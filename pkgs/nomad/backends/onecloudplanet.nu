use ../secrets.nu

const MIN_RAM = 1024

# Nova tags, replace-all-tags and tag filtering on list all need 2.26. 2.79 is
# old enough to be universally available and new enough for all of them.
const NOVA_VERSION = "2.79"

# OpenStack publishes neither country codes nor prices. Both are on their
# website, not in any API, so they live here rather than in the credential file.
# Prices are per hour for the smallest flavor with at least 1 GB.
const REGIONS = {
  "ua-central-1": {cc: "ua", city: "Kyiv", hourly: 0.01}
  "pl-poznan-1": {cc: "pl", city: "Poznan", hourly: 0.01}
  "nl-ams-1": {cc: "nl", city: "Amsterdam", hourly: 0.01}
}

def creds [] {
  secrets get-json "nomad/onecloudplanet"
}

export def configured [] {
  secrets exists "nomad/onecloudplanet"
}

# Keystone hands the token back in a response header, not the body. Application
# credentials are preferred; password auth is accepted because not every project
# is allowed to mint them.
def session [] {
  let c = (creds)

  let body = if ("application_credential_id" in $c) {
    {
      auth: {
        identity: {
          methods: ["application_credential"]
          application_credential: {
            id: $c.application_credential_id
            secret: $c.application_credential_secret
          }
        }
      }
    }
  } else {
    {
      auth: {
        identity: {
          methods: ["password"]
          password: {
            user: {
              name: $c.username
              domain: {name: ($c.user_domain? | default "Default")}
              password: $c.password
            }
          }
        }
        scope: {
          project: {
            name: $c.project_name
            domain: {name: ($c.project_domain? | default "Default")}
          }
        }
      }
    }
  }

  let r = (
    http post --content-type application/json --full --allow-errors
      $"($c.auth_url)/auth/tokens" $body
  )
  if $r.status >= 300 {
    error make {msg: $"keystone auth failed with ($r.status) at ($c.auth_url)"}
  }

  {
    token: ($r.headers.response | where name == "x-subject-token" | get value | first)
    catalog: $r.body.token.catalog
  }
}

def endpoint [s: record, kind: string, region: string] {
  let urls = (
    $s.catalog
    | where type == $kind
    | get endpoints
    | flatten
    | where interface == "public" and region_id == $region
    | get url
  )
  if ($urls | is-empty) {
    error make {msg: $"no public ($kind) endpoint for region ($region)"}
  }
  $urls | first
}

def nova-hdr [s: record] {
  [X-Auth-Token $s.token X-OpenStack-Nova-API-Version $NOVA_VERSION]
}

# Regions the catalog advertises, intersected with the ones we know a country
# for. An unknown region is unusable by `up <cc>` regardless.
def known [s: record] {
  $s.catalog
  | where type == "compute"
  | get endpoints
  | flatten
  | get region_id
  | uniq
  | where {|r| $r in $REGIONS }
}

def default-region [s: record] {
  let r = (known $s | get 0?)
  if $r == null {
    error make {msg: "no compute region in the catalog matches a known country"}
  }
  $r
}

def flavor [s: record, region: string] {
  let nova = (endpoint $s "compute" $region)
  let f = (
    http get --headers (nova-hdr $s) $"($nova)/flavors/detail"
    | get flavors
    | where {|f| $f.ram >= $MIN_RAM and $f.vcpus >= 1 }
    | sort-by ram disk
    | get 0?
  )
  if $f == null {
    error make {msg: $"no flavor with at least ($MIN_RAM) MB in ($region)"}
  }
  $f
}

# Which network gives an instance a routable address is operator-specific, so
# this guesses and says so plainly rather than failing deep inside `create`.
def network [s: record, region: string] {
  if ($env.NOMAD_OCP_NETWORK? | default "") != "" {
    return $env.NOMAD_OCP_NETWORK
  }

  let neutron = (endpoint $s "network" $region)
  let nets = (
    http get --headers [X-Auth-Token $s.token] $"($neutron)/v2.0/networks"
    | get networks
    | where status == "ACTIVE"
  )

  let shared = ($nets | where {|n| ($n.shared? | default false) } | get id?)
  let chosen = (
    if not ($shared | is-empty) {
      $shared | first
    } else {
      $nets | where {|n| not ($n."router:external"? | default false) } | get id? | get 0?
    }
  )
  if $chosen == null {
    error make {
      msg: $"could not pick a network in ($region); set NOMAD_OCP_NETWORK to a neutron network id"
    }
  }
  $chosen
}

export def regions [] {
  let s = (session)
  known $s | each {|r|
    let meta = ($REGIONS | get $r)
    {
      cc: $meta.cc
      city: $meta.city
      region: $r
      plan: (flavor $s $r | get id)
      hourly: $meta.hourly
    }
  }
}

def image-named [s: record, region: string, name: string] {
  let glance = (endpoint $s "image" $region)
  http get --headers [X-Auth-Token $s.token] $"($glance)/v2/images?name=($name)"
  | get images
  | get 0?
}

def nomad-image [s: record, region: string] {
  let glance = (endpoint $s "image" $region)
  http get --headers [X-Auth-Token $s.token] $"($glance)/v2/images"
  | get images
  | where {|i| ($i.name? | default "") | str starts-with "nomad-" }
  | get 0?
}

export def image-id [] {
  let s = (session)
  let img = (nomad-image $s (default-region $s))
  if $img == null { null } else { $img.name | str replace "nomad-" "" }
}

# Their Fleio layer, not OpenStack. Used only to create images: it fetches the
# URL server-side in about half a minute, where a direct Glance upload would push
# the whole image up from here. Everything else in this adapter is Keystone/Nova.
def fleio [c: record] {
  {
    base: ($c.api_url? | default "https://core.ocplanet.cloud")
    hdr: [Authorization $"OpenAPIToken ($c.api_token)"]
  }
}

# Glance's import taskflow is broken on this deployment: web-download and
# glance-direct both fail into any store, while the legacy direct upload their
# panel uses works. The Fleio call below ends in that same direct upload, just
# issued from inside their network.
export def ensure-image [spec: record] {
  let c = (creds)
  let s = (session)
  let region = (default-region $s)
  let glance = (endpoint $s "image" $region)
  let h = [X-Auth-Token $s.token]
  let name = $"nomad-($spec.id)"

  let stale = (image-named $s $region $name)
  if $stale != null {
    if $stale.status == "active" {
      print $"  onecloudplanet: already published as ($stale.id)"
      return $stale.id
    }
    # A record short of `active` holds no usable data and still bills.
    print $"  onecloudplanet: discarding incomplete image ($stale.id)"
    http delete --headers $h --allow-errors $"($glance)/v2/images/($stale.id)"
  }

  let f = (fleio $c)
  print $"  onecloudplanet: asking their backend to fetch ($spec.url)"

  let r = (
    http post --headers $f.hdr --content-type multipart/form-data --full --allow-errors
      $"($f.base)/backend/api/openstack/images" {
        active_client: $c.active_client
        name: $name
        source: "url"
        url: $spec.url
        disk_format: "raw"
        region: $region
        architecture: "x86_64"
        min_disk: 1
        min_ram: 1
      }
  )
  if $r.status >= 300 {
    error make {msg: $"onecloudplanet refused the image request with ($r.status): ($r.body | to json -r)"}
  }

  # Poll Glance rather than their wrapper, so the success condition is the same
  # one `create` later depends on.
  for i in 1..120 {
    let cur = (image-named $s $region $name)
    if $cur != null {
      if $cur.status == "active" {
        print $"  onecloudplanet: stored in ($cur.stores? | default '?')"
        return $cur.id
      }
      if $cur.status in ["killed" "deleted"] {
        error make {msg: $"onecloudplanet rejected the image, status ($cur.status)"}
      }
    }
    if ($i mod 6) == 0 {
      print $"  onecloudplanet: still fetching, ($i * 5)s elapsed"
    }
    sleep 5sec
  }
  error make {msg: $"onecloudplanet image ($name) never became active"}
}

export def destroy-image [id: string] {
  let s = (session)
  let region = (default-region $s)
  let img = (image-named $s $region $"nomad-($id)")
  if $img != null {
    let glance = (endpoint $s "image" $region)
    http delete --headers [X-Auth-Token $s.token] $"($glance)/v2/images/($img.id)"
    print $"  onecloudplanet: deleted old image ($img.id)"
  }
}

export def create [spec: record] {
  let s = (session)
  let nova = (endpoint $s "compute" $spec.region)
  let h = (nova-hdr $s)

  let img = (nomad-image $s $spec.region)
  if $img == null {
    error make {msg: "no nomad image on onecloudplanet; run `nomad image push`"}
  }

  let server = (
    http post --headers $h --content-type application/json $"($nova)/servers" {
      server: {
        name: $spec.hostname
        imageRef: $img.id
        flavorRef: $spec.plan
        networks: [{uuid: (network $s $spec.region)}]
        # Nova takes user-data base64-encoded, like Vultr and unlike DigitalOcean.
        user_data: ($spec.user_data | encode base64)
        tags: $spec.tags
      }
    }
    | get server
  )

  # The address is assigned after the build starts, so it is not in the create
  # response.
  mut ip = null
  for _ in 1..30 {
    let cur = (http get --headers $h $"($nova)/servers/($server.id)" | get server)
    let addrs = ($cur.addresses? | default {} | values | flatten | where version == 4)
    if not ($addrs | is-empty) {
      $ip = ($addrs | get addr | first)
      break
    }
    sleep 2sec
  }

  {id: $server.id, ipv4: $ip}
}

export def list [] {
  let s = (session)
  mut out = []
  for region in (known $s) {
    let nova = (endpoint $s "compute" $region)
    let rate = ($REGIONS | get $region | get hourly)
    let servers = (
      http get --headers (nova-hdr $s) $"($nova)/servers/detail?tags=nomad" | get servers
    )
    $out = ($out | append ($servers | each {|v|
      {
        id: $v.id
        region: $region
        tags: ($v.tags? | default [])
        created: ($v.created | into datetime)
        hourly: $rate
      }
    }))
  }
  $out
}

export def destroy [id: string] {
  let s = (session)
  let nova = (endpoint $s "compute" (default-region $s))
  http delete --headers (nova-hdr $s) $"($nova)/servers/($id)"
}

# Unlike DigitalOcean, Nova has a genuine replace-all-tags call.
export def retag [id: string, tags: list<string>] {
  let s = (session)
  let nova = (endpoint $s "compute" (default-region $s))
  http put --headers (nova-hdr $s) --content-type application/json $"($nova)/servers/($id)/tags" {
    tags: $tags
  }
}

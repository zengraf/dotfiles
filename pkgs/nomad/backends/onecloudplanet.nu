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

export def ensure-image [url: string, id: string] {
  let s = (session)
  let region = (default-region $s)
  let glance = (endpoint $s "image" $region)
  let h = [X-Auth-Token $s.token]

  let existing = (image-named $s $region $"nomad-($id)")

  let img = if $existing != null {
    print $"  onecloudplanet: adopting in-flight image ($existing.id)"
    $existing
  } else {
    let created = (
      http post --headers $h --content-type application/json $"($glance)/v2/images" {
        name: $"nomad-($id)"
        disk_format: "raw"
        container_format: "bare"
        visibility: "private"
      }
    )
    # Glance fetches the URL itself rather than us streaming 1.6 GiB through here.
    http post --headers $h --content-type application/json $"($glance)/v2/images/($created.id)/import" {
      method: {name: "web-download", uri: $url}
    }
    print $"  onecloudplanet: image ($created.id) created, importing"
    $created
  }

  for i in 1..360 {
    let cur = (http get --headers $h $"($glance)/v2/images/($img.id)")
    if $cur.status == "active" {
      print "  onecloudplanet: import complete"
      return $img.id
    }
    if $cur.status in ["killed" "deleted"] {
      error make {msg: $"onecloudplanet rejected the image at ($url)"}
    }
    if ($i mod 6) == 0 {
      print $"  onecloudplanet: still importing \(($cur.status)\), ($i * 10)s elapsed"
    }
    sleep 10sec
  }
  error make {msg: $"onecloudplanet image ($img.id) did not finish importing"}
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

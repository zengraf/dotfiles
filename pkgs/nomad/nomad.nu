use backends/mod.nu
use secrets.nu
use r2.nu

const TAG = "nomad"

# The wrapper bakes in the flake it was built from. Falling back to the checkout
# keeps the CLI runnable from source.
const CHECKOUT = (path self | path dirname | path join ".." "..")

def flake [] {
  $env.NOMAD_FLAKE? | default $CHECKOUT
}

# The CLI belongs to the desktop app, which puts it somewhere Nushell does not
# inherit, so PATH alone is not enough to find it.
def ts [] {
  let on_path = (which tailscale | get path? | get 0?)
  if $on_path != null { return $on_path }

  let found = (
    [
      "/opt/homebrew/bin/tailscale"
      "/usr/local/bin/tailscale"
      "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    ]
    | where {|p| $p | path exists }
    | get 0?
  )
  if $found == null {
    error make {msg: "tailscale CLI not found on PATH or in the usual places"}
  }
  $found
}

# eval, not build: this must not realise a 2 GB derivation.
def image-id [] {
  let p = (nix eval --raw $"((flake))#packages.x86_64-linux.nomad-image.outPath")
  $p | path basename | split row "-" | first
}

def tailscale-token [] {
  let oauth = (secrets get-json "nomad/tailscale-oauth")
  # Tailscale's documented example omits grant_type.
  http post --content-type application/x-www-form-urlencoded https://api.tailscale.com/api/v2/oauth/token {
    client_id: $oauth.client_id
    client_secret: $oauth.client_secret
  } | get access_token
}

def mint-authkey [ttl: duration] {
  let token = (tailscale-token)
  http post --headers [Authorization $"Bearer ($token)"] --content-type application/json https://api.tailscale.com/api/v2/tailnet/-/keys {
    description: "nomad ephemeral exit node"
    expirySeconds: ((($ttl | into int) / 1_000_000_000) | into int)
    capabilities: {
      devices: {
        create: {
          reusable: false
          ephemeral: true
          preauthorized: true
          tags: [$"tag:($TAG)"]
        }
      }
    }
  } | get key
}

# Adapters are always dispatched from a `for`, never an `each`. An `each` block's
# pipeline input is the loop record, `do` forwards it into the closure, and the
# adapter's `http` command then treats it as a request body and rejects it.
# Piping `null` does not help: `http delete` rejects nothing as a body too. A
# `for` block has no pipeline input at all.

# Regions, plans and prices all come from the provider APIs. Only configured
# backends appear, because DigitalOcean's catalogue needs authentication.
def catalogue [] {
  mut rows = []
  for b in (active) {
    let regions = (do ($b.adapter.regions))
    $rows = ($rows | append ($regions | each {|r| $r | insert backend $b.name }))
  }
  $rows
}

# Every API call goes through this. A half-provisioned machine must still destroy
# what it created elsewhere, so an unconfigured backend is skipped, not fatal.
def active [] {
  mut out = []
  for b in (mod registry | transpose name adapter) {
    if (do ($b.adapter.configured)) { $out = ($out | append $b) }
  }
  $out
}

def pick [cat: list, cc: string, backend?: string, region?: string] {
  let candidates = (
    $cat
    | where cc == $cc
    | where {|r| $backend == null or $r.backend == $backend }
    | where {|r| $region == null or $r.region == $region }
    | sort-by hourly
  )
  if ($candidates | is-empty) {
    let served = ($cat | get cc | uniq | sort | str join " ")
    error make {msg: $"no configured backend serves '($cc)'. Available: ($served)"}
  }
  $candidates | first
}

def live [] {
  mut out = []
  for b in (active) {
    let rows = (do ($b.adapter.list))
    $out = ($out | append ($rows | each {|i| $i | insert backend $b.name }))
  }
  $out
}

# `into datetime` reads a bare integer as nanoseconds, so seconds must be scaled.
def expiry-of [tags: list<string>] {
  let tag = ($tags | where {|x| $x | str starts-with "nomad-exp-" } | get 0?)
  if $tag == null {
    null
  } else {
    ($tag | str replace "nomad-exp-" "" | into int) * 1_000_000_000 | into datetime
  }
}

# Nu's default float precision is 2 decimals, which shows every plan as $0.01.
export def "main regions" [] {
  catalogue
  | select cc city backend region plan hourly
  | sort-by cc hourly
  | update hourly {|r| $"$($r.hourly | into string --decimals 5)/hr" }
}

export def "main up" [
  cc: string                      # ISO country code, e.g. `in`
  --ttl: duration = 4hr           # destroyed by the reaper after this
  --backend: string               # override cheapest-first selection
  --region: string                # override cheapest-first selection
] {
  let target = (pick (catalogue) $cc $backend $region)
  let adapter = (mod registry | get $target.backend)

  let want = (image-id)
  let published = (do ($adapter.image-id))
  if $published != $want {
    error make {msg: $"published image is ($published), config wants ($want); run `nomad image push`"}
  }

  let name = $"nomad-($cc)-(random chars --length 4 | str lowercase)"
  let expires = ((date now) + $ttl)

  print $"provisioning ($name) on ($target.backend)/($target.region), expires ($expires | format date '%H:%M')"

  let instance = (do ($adapter.create) {
    region: $target.region
    plan: $target.plan
    hostname: $name
    tags: [$TAG $"nomad-exp-(($expires | format date '%s'))"]
    user_data: ({authkey: (mint-authkey $ttl), hostname: $name} | to json)
  })

  print $"($target.backend) instance ($instance.id) at ($instance.ipv4), waiting for it to join"

  mut seen = false
  for i in 1..60 {
    if (^(ts) status --json | from json | get Peer | values | any {|p| $p.HostName == $name }) {
      $seen = true
      print $"joined after ($i * 2)s"
      break
    }
    if ($i mod 15) == 0 { print $"  still waiting, ($i * 2)s elapsed" }
    sleep 2sec
  }
  if not $seen {
    error make {msg: $"($name) never joined the tailnet. Instance ($instance.id) is still running; run `nomad down`"}
  }

  ^(ts) set $"--exit-node=($name)"

  let geo = (http get https://ipinfo.io/json)
  print $"egress ($geo.ip) in ($geo.city), ($geo.country)"
}

export def "main down" [] {
  mut gone = []
  for i in (live) {
    do ((mod registry | get $i.backend).destroy) $i.id
    print $"destroyed ($i.backend)/($i.id) in ($i.region)"
    $gone = ($gone | append ($i | select backend id region))
  }
  if ($gone | is-empty) { print "nothing to destroy" } else { $gone }
}

export def "main status" [] {
  live | each {|i|
    let up = ((date now) - $i.created)
    # Vultr bills a 1h minimum, so a partial hour would understate the cost.
    let hours = ([1 ($up / 1hr | math ceil)] | math max)
    $i | insert uptime $up | insert cost ($hours * $i.hourly) | insert expires (expiry-of $i.tags)
  }
  | select backend id region uptime expires cost
  | update cost {|r| $"$($r.cost | into string --decimals 4)" }
}

export def "main renew" [--ttl: duration = 4hr] {
  let expires = ((date now) + $ttl)
  mut out = []
  for i in (live) {
    do ((mod registry | get $i.backend).retag) $i.id [$TAG $"nomad-exp-(($expires | format date '%s'))"]
    $out = ($out | append ($i | select backend id | insert expires $expires))
  }
  $out
}

export def "main image push" [] {
  print "building image (x86_64-linux, this is the slow part)"
  let out = (nix build $"((flake))#packages.x86_64-linux.nomad-image" --no-link --print-out-paths)
  let id = ($out | path basename | split row "-" | first)
  let size = (ls ($out | path join "nomad.img") | get size | first)
  print $"built ($id), ($size)"

  print "uploading to R2 (skipped if unchanged)"
  let url = (r2 publish $out $id (secrets get-json "r2"))
  print $"published ($url)"

  for b in (active) {
    let old = (do ($b.adapter.image-id))
    if $old == $id {
      print $"($b.name): already at ($id)"
    } else {
      print $"($b.name): importing ($id), replacing ($old | default 'nothing')"
      do ($b.adapter.ensure-image) {url: $url, path: ($out | path join "nomad.img"), id: $id}
      if $old != null { do ($b.adapter.destroy-image) $old }
    }
  }
  print "done"
}

# An instance with no expiry tag is an orphan from a failed run. It can never
# expire on its own, so it goes too.
export def "main reap" [] {
  let now = (date now)
  for i in (live) {
    let expires = (expiry-of $i.tags)
    if $expires == null or $expires < $now {
      do ((mod registry | get $i.backend).destroy) $i.id
      print $"reaped ($i.backend)/($i.id) ($expires | default 'no expiry tag')"
    }
  }
}

export def main [] {
  print "usage: nomad up <cc> | down | status | regions | renew | reap | image push"
}

use backends/mod.nu
use secrets.nu
use r2.nu

const TAG = "nomad"

# Store hash of the image the current config would produce. Evaluated, never
# built — `nix eval` does not realise the derivation.
def image-id [] {
  let p = (nix eval --raw $"($env.NOMAD_FLAKE)#packages.x86_64-linux.nomad-image.outPath")
  $p | path basename | split row "-" | first
}

def tailscale-token [] {
  let oauth = (secrets get-json "tailscale-oauth")
  # Tailscale's documented example posts only the two credentials, no grant_type.
  http post --content-type application/x-www-form-urlencoded https://api.tailscale.com/api/v2/oauth/token {
    client_id: $oauth.client_id
    client_secret: $oauth.client_secret
  } | get access_token
}

def mint-authkey [ttl: duration] {
  let token = (tailscale-token)
  http post --headers [Authorization $"Bearer ($token)"] https://api.tailscale.com/api/v2/tailnet/-/keys {
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

# Every backend's regions, flattened, with the backend name attached.
def catalogue [] {
  mod registry | transpose name adapter | each {|b|
    do ($b.adapter.regions) | each {|r| $r | insert backend $b.name }
  } | flatten
}

def pick [cc: string, backend?: string, region?: string] {
  let candidates = (
    catalogue
    | where cc == $cc
    | where {|r| $backend == null or $r.backend == $backend }
    | where {|r| $region == null or $r.region == $region }
    | sort-by hourly
  )
  if ($candidates | is-empty) {
    error make {msg: $"no backend serves country code '($cc)'"}
  }
  $candidates | first
}

def live [] {
  mod registry | transpose name adapter | each {|b|
    do ($b.adapter.list) | each {|i| $i | insert backend $b.name }
  } | flatten
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

# Prices are formatted here rather than carried as strings: Nu's default float
# precision is 2 decimals, which renders every plan as $0.01 and makes
# cheapest-first look arbitrary.
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
  let target = (pick $cc $backend $region)
  let adapter = (mod registry | get $target.backend)

  let want = (image-id)
  let published = (do ($adapter.image-id))
  if $published != $want {
    error make {msg: $"published image is ($published), config wants ($want) — run `nomad image push`"}
  }

  let name = $"nomad-($cc)-(random chars --length 4 | str lowercase)"
  let expires = ((date now) + $ttl)

  print $"provisioning ($name) on ($target.backend)/($target.region) — expires ($expires | format date '%H:%M')"

  let instance = (do ($adapter.create) {
    region: $target.region
    plan: $target.plan
    hostname: $name
    tags: [$TAG $"nomad-exp-(($expires | format date '%s'))"]
    user_data: ({authkey: (mint-authkey $ttl), hostname: $name} | to json)
  })

  # The node joins on its own; wait for it to show up as a peer.
  mut seen = false
  for _ in 1..60 {
    if (tailscale status --json | from json | get Peer | values | any {|p| $p.HostName == $name }) {
      $seen = true
      break
    }
    sleep 2sec
  }
  if not $seen {
    error make {msg: $"($name) never joined the tailnet — instance ($instance.id) left running, run `nomad down`"}
  }

  tailscale set $"--exit-node=($name)"

  let geo = (http get https://ipinfo.io/json)
  print $"egress ($geo.ip) — ($geo.city), ($geo.country)"
}

export def "main down" [] {
  tailscale set --exit-node=
  let gone = (live | each {|i|
    do ((mod registry | get $i.backend).destroy) $i.id
    $i | select backend id region
  })
  if ($gone | is-empty) { print "nothing to destroy" } else { $gone }
}

export def "main status" [] {
  live | each {|i|
    let up = ((date now) - $i.created)
    # Vultr bills a 1h minimum; charging a partial hour would understate it.
    let hours = ([1 ($up / 1hr | math ceil)] | math max)
    $i | insert uptime $up | insert cost ($hours * $i.hourly) | insert expires (expiry-of $i.tags)
  }
  | select backend id region uptime expires cost
  | update cost {|r| $"$($r.cost | into string --decimals 4)" }
}

export def "main renew" [--ttl: duration = 4hr] {
  let expires = ((date now) + $ttl)
  live | each {|i|
    do ((mod registry | get $i.backend).retag) $i.id [$TAG $"nomad-exp-(($expires | format date '%s'))"]
    $i | select backend id | insert expires $expires
  }
}

export def "main image push" [] {
  let out = (nix build $"($env.NOMAD_FLAKE)#packages.x86_64-linux.nomad-image" --no-link --print-out-paths)
  let id = ($out | path basename | split row "-" | first)
  let url = (r2 publish $out $id (secrets get-json "r2"))

  mod registry | transpose name adapter | each {|b|
    let old = (do ($b.adapter.image-id))
    if $old == $id {
      print $"($b.name): already at ($id)"
    } else {
      print $"($b.name): publishing ($id)"
      do ($b.adapter.ensure-image) $url $id
      if $old != null { do ($b.adapter.destroy-image) $old }
    }
  }
}

# The dead-man switch, run from a timer on the router so that a dead operator
# machine cannot leave an instance billing. An instance carrying no expiry tag is
# an orphan from a failed run and can never expire on its own, so it goes too.
export def "main reap" [] {
  let now = (date now)
  live | each {|i|
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

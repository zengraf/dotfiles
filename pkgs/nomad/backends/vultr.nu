use ../secrets.nu

const API = "https://api.vultr.com/v2"

# age-plugin-se prompts for biometry on every decrypt, so each exported verb
# unlocks once and threads the headers through. Calling this per request would
# ask a hundred times inside the import poll.
def auth [] {
  let token = (secrets get-json "nomad/vultr" | get token)
  [Authorization $"Bearer ($token)"]
}

export def configured [] {
  secrets exists "nomad/vultr"
}

const MIN_RAM = 1024

# Vultr's catalogue is unauthenticated and carries ISO country codes, so every
# region it sells is usable without listing any of them here.
export def regions [] {
  let plans = (http get $"($API)/plans?per_page=500" | get plans)

  http get $"($API)/regions?per_page=500"
  | get regions
  | each {|r|
    let best = (
      $plans
      | where {|p| ($r.id in $p.locations) and $p.ram >= $MIN_RAM }
      | sort-by hourly_cost
      | get 0?
    )
    if $best == null {
      null
    } else {
      {
        cc: ($r.country | str lowercase)
        city: $r.city
        region: $r.id
        plan: $best.id
        hourly: $best.hourly_cost
      }
    }
  }
  | compact
}

def prices [] {
  http get $"($API)/plans?per_page=500"
  | get plans
  | reduce --fold {} {|p, acc| $acc | insert $p.id $p.hourly_cost }
}

# The image's store hash lives in the snapshot description.
def snapshot [h: list] {
  http get --headers $h $"($API)/snapshots"
  | get snapshots
  | where {|s| ($s.description? | default "") | str starts-with "nomad-" }
  | get 0?
}

export def image-id [] {
  let snap = (snapshot (auth))
  if $snap == null { null } else { $snap.description | str replace "nomad-" "" }
}

export def ensure-image [url: string, id: string] {
  let h = (auth)

  # An earlier run may have started this import and given up waiting. Adopt it,
  # or a second copy imports under the same description.
  let existing = (
    http get --headers $h $"($API)/snapshots"
    | get snapshots
    | where description == $"nomad-($id)"
    | get 0?
  )

  let created = if $existing != null {
    print $"  vultr: adopting in-flight snapshot ($existing.id)"
    $existing
  } else {
    # Raw only, uncompressed, fetched from a public URL.
    let c = (
      http post --headers $h --content-type application/json $"($API)/snapshots/create-from-url" {
        url: $url
        description: $"nomad-($id)"
      }
      | get snapshot
    )
    print $"  vultr: snapshot ($c.id) created, importing"
    $c
  }

  # Asynchronous; the snapshot is unbootable until it completes, and a 1.6 GiB
  # import can run well past twenty minutes.
  for i in 1..360 {
    let snap = (http get --headers $h $"($API)/snapshots/($created.id)" | get snapshot)
    if $snap.status == "complete" {
      print $"  vultr: import complete \(($snap.size? | default 0 | into filesize)\)"
      return $created.id
    }
    if $snap.status == "failed" {
      error make {msg: $"vultr rejected the image at ($url)"}
    }
    if ($i mod 6) == 0 {
      print $"  vultr: still importing, ($i * 10)s elapsed"
    }
    sleep 10sec
  }
  error make {msg: $"vultr snapshot ($created.id) did not finish importing"}
}

export def destroy-image [id: string] {
  let h = (auth)
  let snap = (
    http get --headers $h $"($API)/snapshots"
    | get snapshots
    | where description == $"nomad-($id)"
    | get 0?
  )
  if $snap != null {
    http delete --headers $h $"($API)/snapshots/($snap.id)"
    print $"  vultr: deleted old snapshot ($snap.id)"
  }
}

export def create [spec: record] {
  let h = (auth)
  let snap = (snapshot $h)
  if $snap == null {
    error make {msg: "no nomad snapshot on vultr; run `nomad image push`"}
  }

  let instance = (
    http post --headers $h --content-type application/json $"($API)/instances" {
      region: $spec.region
      plan: $spec.plan
      snapshot_id: $snap.id
      hostname: $spec.hostname
      label: $spec.hostname
      tags: $spec.tags
      enable_ipv6: true
      # Base64 here, plain text on DigitalOcean.
      user_data: ($spec.user_data | encode base64)
    }
    | get instance
  )

  {id: $instance.id, ipv4: $instance.main_ip}
}

export def list [] {
  let h = (auth)
  let rates = (prices)

  http get --headers $h $"($API)/instances?tag=nomad"
  | get instances
  | each {|i|
    {
      id: $i.id
      region: $i.region
      tags: ($i.tags? | default [])
      created: ($i.date_created | into datetime)
      hourly: (if ($i.plan in $rates) { $rates | get $i.plan } else { 0.0 })
    }
  }
}

export def destroy [id: string] {
  http delete --headers (auth) $"($API)/instances/($id)"
}

export def retag [id: string, tags: list<string>] {
  http patch --headers (auth) --content-type application/json $"($API)/instances/($id)" {tags: $tags}
}

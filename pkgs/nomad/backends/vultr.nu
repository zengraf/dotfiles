use ../secrets.nu

const API = "https://api.vultr.com/v2"

def auth [] {
  let token = (secrets get-json "nomad/vultr" | get token)
  [Authorization $"Bearer ($token)"]
}

export def configured [] {
  secrets exists "nomad/vultr"
}

# Adding a destination is a row here; nothing else in the CLI knows geography.
export def regions [] {
  [
    {
      cc: "in"
      city: "Bangalore"
      region: "blr"
      plan: "vc2-1c-1gb"
      hourly: 0.007
    }
    {
      cc: "in"
      city: "Delhi"
      region: "del"
      plan: "vc2-1c-1gb"
      hourly: 0.007
    }
  ]
}

def rate [region: string] {
  regions | where region == $region | get hourly? | get 0? | default 0.007
}

# The image's store hash lives in the snapshot description.
def snapshot [] {
  http get --headers (auth) $"($API)/snapshots"
  | get snapshots
  | where {|s| ($s.description? | default "") | str starts-with "nomad-" }
  | get 0?
}

export def image-id [] {
  let snap = (snapshot)
  if $snap == null { null } else { $snap.description | str replace "nomad-" "" }
}

export def ensure-image [url: string, id: string] {
  # Raw only, uncompressed, fetched from a public URL.
  let created = (
    http post --headers (auth) $"($API)/snapshots/create-from-url" {
      url: $url
      description: $"nomad-($id)"
    }
    | get snapshot
  )

  # Asynchronous; the snapshot is unbootable until it completes.
  for _ in 1..120 {
    let status = (http get --headers (auth) $"($API)/snapshots/($created.id)" | get snapshot.status)
    if $status == "complete" { return $created.id }
    if $status == "failed" { error make {msg: $"vultr rejected the image at ($url)"} }
    sleep 10sec
  }
  error make {msg: $"vultr snapshot ($created.id) did not finish importing"}
}

export def destroy-image [id: string] {
  let snap = (
    http get --headers (auth) $"($API)/snapshots"
    | get snapshots
    | where description == $"nomad-($id)"
    | get 0?
  )
  if $snap != null {
    http delete --headers (auth) $"($API)/snapshots/($snap.id)"
  }
}

export def create [spec: record] {
  let snap = (snapshot)
  if $snap == null {
    error make {msg: "no nomad snapshot on vultr; run `nomad image push`"}
  }

  let instance = (
    http post --headers (auth) $"($API)/instances" {
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
  http get --headers (auth) $"($API)/instances?tag=nomad"
  | get instances
  | each {|i|
    {
      id: $i.id
      region: $i.region
      tags: ($i.tags? | default [])
      created: ($i.date_created | into datetime)
      hourly: (rate $i.region)
    }
  }
}

export def destroy [id: string] {
  http delete --headers (auth) $"($API)/instances/($id)"
}

export def retag [id: string, tags: list<string>] {
  http patch --headers (auth) $"($API)/instances/($id)" {tags: $tags}
}

use ../secrets.nu

const API = "https://api.digitalocean.com/v2"

def creds [] {
  secrets get-json "nomad/digitalocean"
}

def auth [] {
  let token = (creds | get token)
  [Authorization $"Bearer ($token)"]
}

export def configured [] {
  secrets exists "nomad/digitalocean"
}

export def regions [] {
  [
    {
      cc: "in"
      city: "Bangalore"
      region: "blr1"
      plan: "s-1vcpu-1gb"
      hourly: 0.00744
    }
  ]
}

def rate [region: string] {
  regions | where region == $region | get hourly? | get 0? | default 0.00744
}

def image [] {
  http get --headers (auth) $"($API)/images?private=true"
  | get images
  | where {|i| ($i.name? | default "") | str starts-with "nomad-" }
  | get 0?
}

export def image-id [] {
  let img = (image)
  if $img == null { null } else { $img.name | str replace "nomad-" "" }
}

export def ensure-image [url: string, id: string] {
  # DigitalOcean fetches the URL itself and fails if the host will not answer HEAD.
  let created = (
    http post --headers (auth) --content-type application/json $"($API)/images" {
      name: $"nomad-($id)"
      url: $url
      # Images land in one region and are transferred on demand at create time.
      region: (regions | get region | first)
      distribution: "Unknown"
      description: "nomad ephemeral exit node"
    }
    | get image
  )

  for _ in 1..120 {
    let status = (http get --headers (auth) $"($API)/images/($created.id)" | get image.status)
    if $status == "available" { return $created.id }
    if $status == "deleted" { error make {msg: $"digitalocean rejected the image at ($url)"} }
    sleep 10sec
  }
  error make {msg: $"digitalocean image ($created.id) did not finish importing"}
}

export def destroy-image [id: string] {
  let img = (
    http get --headers (auth) $"($API)/images?private=true"
    | get images
    | where name == $"nomad-($id)"
    | get 0?
  )
  if $img != null {
    http delete --headers (auth) $"($API)/images/($img.id)"
  }
}

export def create [spec: record] {
  let img = (image)
  if $img == null {
    error make {msg: "no nomad image on digitalocean; run `nomad image push`"}
  }

  # Images are region-scoped. Transfer is free but not instant.
  if not ($img.regions? | default [] | any {|r| $r == $spec.region }) {
    http post --headers (auth) --content-type application/json $"($API)/images/($img.id)/actions" {
      type: "transfer"
      region: $spec.region
    }
    for _ in 1..120 {
      let ready = (
        http get --headers (auth) $"($API)/images/($img.id)"
        | get image.regions
        | any {|r| $r == $spec.region }
      )
      if $ready { break }
      sleep 10sec
    }
  }

  let droplet = (
    http post --headers (auth) --content-type application/json $"($API)/droplets" {
      name: $spec.hostname
      region: $spec.region
      size: $spec.plan
      image: $img.id
      tags: $spec.tags
      # Never used, but a custom-image droplet without one has password auth
      # disabled and no console reset, so it would be unreachable.
      ssh_keys: [(creds | get ssh_key)]
      ipv6: false
      # Plain text here, base64 on Vultr.
      user_data: $spec.user_data
    }
    | get droplet
  )

  {id: $droplet.id, ipv4: ($droplet.networks?.v4? | default [] | where type == "public" | get ip_address? | get 0?)}
}

export def list [] {
  http get --headers (auth) $"($API)/droplets?tag_name=nomad"
  | get droplets
  | each {|d|
    {
      id: $d.id
      region: $d.region.slug
      tags: ($d.tags? | default [])
      created: ($d.created_at | into datetime)
      hourly: (rate $d.region.slug)
    }
  }
}

export def destroy [id: string] {
  http delete --headers (auth) $"($API)/droplets/($id)"
}

# There is no "set tags" call: a tag is an object you attach resources to, so
# renewal means detaching the stale expiry tag and attaching a fresh one.
export def retag [id: string, tags: list<string>] {
  let resource = [{resource_id: ($id | into string), resource_type: "droplet"}]

  let current = (
    http get --headers (auth) $"($API)/droplets/($id)"
    | get droplet.tags
    | where {|t| $t | str starts-with "nomad-exp-" }
  )
  for stale in $current {
    http delete --headers (auth) --content-type application/json --data {resources: $resource} $"($API)/tags/($stale)/resources"
  }

  for tag in ($tags | where {|t| $t not-in $current }) {
    try { http post --headers (auth) --content-type application/json $"($API)/tags" {name: $tag} }
    http post --headers (auth) --content-type application/json $"($API)/tags/($tag)/resources" {resources: $resource}
  }
}

use ../secrets.nu

const API = "https://api.digitalocean.com/v2"

def creds [] {
  secrets get-json "nomad/digitalocean"
}

# age-plugin-se prompts for biometry on every decrypt, so each exported verb
# unlocks once and threads the headers through. Calling this per request would
# ask a hundred times inside the import poll.
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

def image [h: list] {
  http get --headers $h $"($API)/images?private=true"
  | get images
  | where {|i| ($i.name? | default "") | str starts-with "nomad-" }
  | get 0?
}

export def image-id [] {
  let img = (image (auth))
  if $img == null { null } else { $img.name | str replace "nomad-" "" }
}

export def ensure-image [url: string, id: string] {
  let h = (auth)

  # An earlier run may have started this import and given up waiting. Adopt it,
  # or a second copy imports under the same name.
  let existing = (
    http get --headers $h $"($API)/images?private=true"
    | get images
    | where name == $"nomad-($id)"
    | get 0?
  )

  let created = if $existing != null {
    print $"  digitalocean: adopting in-flight image ($existing.id)"
    $existing
  } else {
    # DigitalOcean fetches the URL itself and fails if the host will not answer HEAD.
    let c = (
      http post --headers $h --content-type application/json $"($API)/images" {
        name: $"nomad-($id)"
        url: $url
        # Images land in one region and are transferred on demand at create time.
        region: (regions | get region | first)
        distribution: "Unknown"
        description: "nomad ephemeral exit node"
      }
      | get image
    )
    print $"  digitalocean: image ($c.id) created, importing"
    $c
  }

  # A 1.6 GiB import can run well past twenty minutes.
  for i in 1..360 {
    let img = (http get --headers $h $"($API)/images/($created.id)" | get image)
    if $img.status == "available" {
      print "  digitalocean: import complete"
      return $created.id
    }
    if $img.status == "deleted" {
      error make {msg: $"digitalocean rejected the image at ($url)"}
    }
    if ($i mod 6) == 0 {
      print $"  digitalocean: still importing \(($img.status)\), ($i * 10)s elapsed"
    }
    sleep 10sec
  }
  error make {msg: $"digitalocean image ($created.id) did not finish importing"}
}

export def destroy-image [id: string] {
  let h = (auth)
  let img = (
    http get --headers $h $"($API)/images?private=true"
    | get images
    | where name == $"nomad-($id)"
    | get 0?
  )
  if $img != null {
    http delete --headers $h $"($API)/images/($img.id)"
    print $"  digitalocean: deleted old image ($img.id)"
  }
}

export def create [spec: record] {
  let h = (auth)
  let img = (image $h)
  if $img == null {
    error make {msg: "no nomad image on digitalocean; run `nomad image push`"}
  }

  # Images are region-scoped. Transfer is free but not instant.
  if not ($img.regions? | default [] | any {|r| $r == $spec.region }) {
    print $"  digitalocean: transferring image to ($spec.region)"
    http post --headers $h --content-type application/json $"($API)/images/($img.id)/actions" {
      type: "transfer"
      region: $spec.region
    }
    for _ in 1..120 {
      let ready = (
        http get --headers $h $"($API)/images/($img.id)"
        | get image.regions
        | any {|r| $r == $spec.region }
      )
      if $ready { break }
      sleep 10sec
    }
  }

  let droplet = (
    http post --headers $h --content-type application/json $"($API)/droplets" {
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
  let h = (auth)
  let resource = [{resource_id: ($id | into string), resource_type: "droplet"}]

  let current = (
    http get --headers $h $"($API)/droplets/($id)"
    | get droplet.tags
    | where {|t| $t | str starts-with "nomad-exp-" }
  )
  for stale in $current {
    http delete --headers $h --content-type application/json --data {resources: $resource} $"($API)/tags/($stale)/resources"
  }

  for tag in ($tags | where {|t| $t not-in $current }) {
    try { http post --headers $h --content-type application/json $"($API)/tags" {name: $tag} }
    http post --headers $h --content-type application/json $"($API)/tags/($tag)/resources" {resources: $resource}
  }
}

use vultr.nu
use digitalocean.nu

# Nu resolves `use` at parse time, so backends are listed rather than discovered.
export def registry [] {
  {
    vultr: {
      configured: {|| vultr configured }
      regions: {|| vultr regions }
      image-id: {|| vultr image-id }
      ensure-image: {|url, id| vultr ensure-image $url $id }
      destroy-image: {|id| vultr destroy-image $id }
      create: {|spec| vultr create $spec }
      list: {|| vultr list }
      destroy: {|id| vultr destroy $id }
      retag: {|id, tags| vultr retag $id $tags }
    }
    digitalocean: {
      configured: {|| digitalocean configured }
      regions: {|| digitalocean regions }
      image-id: {|| digitalocean image-id }
      ensure-image: {|url, id| digitalocean ensure-image $url $id }
      destroy-image: {|id| digitalocean destroy-image $id }
      create: {|spec| digitalocean create $spec }
      list: {|| digitalocean list }
      destroy: {|id| digitalocean destroy $id }
      retag: {|id, tags| digitalocean retag $id $tags }
    }
  }
}

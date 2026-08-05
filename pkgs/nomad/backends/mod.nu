use vultr.nu
use digitalocean.nu
use onecloudplanet.nu

# Nu resolves `use` at parse time, so backends are listed rather than discovered.
export def registry [] {
  {
    vultr: {
      configured: {|| vultr configured }
      regions: {|| vultr regions }
      image-id: {|| vultr image-id }
      ensure-image: {|spec| vultr ensure-image $spec }
      destroy-image: {|id| vultr destroy-image $id }
      create: {|spec| vultr create $spec }
      list: {|| vultr list }
      destroy: {|id| vultr destroy $id }
      retag: {|id, tags| vultr retag $id $tags }
    }
    onecloudplanet: {
      configured: {|| onecloudplanet configured }
      regions: {|| onecloudplanet regions }
      image-id: {|| onecloudplanet image-id }
      ensure-image: {|spec| onecloudplanet ensure-image $spec }
      destroy-image: {|id| onecloudplanet destroy-image $id }
      create: {|spec| onecloudplanet create $spec }
      list: {|| onecloudplanet list }
      destroy: {|id| onecloudplanet destroy $id }
      retag: {|id, tags| onecloudplanet retag $id $tags }
    }
    digitalocean: {
      configured: {|| digitalocean configured }
      regions: {|| digitalocean regions }
      image-id: {|| digitalocean image-id }
      ensure-image: {|spec| digitalocean ensure-image $spec }
      destroy-image: {|id| digitalocean destroy-image $id }
      create: {|spec| digitalocean create $spec }
      list: {|| digitalocean list }
      destroy: {|id| digitalocean destroy $id }
      retag: {|id, tags| digitalocean retag $id $tags }
    }
  }
}

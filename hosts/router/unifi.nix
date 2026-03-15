{ pkgs, ... }: {
  services.unifi = {
    enable = true;
    openFirewall = false;
    mongodbPackage = pkgs.mongodb-no-avx;
    maximumJavaHeapSize = 256;
  };

  systemd.services.unifi.preStart = ''
    PROPS="/var/lib/unifi/data/system.properties"
    mkdir -p "$(dirname "$PROPS")"
    touch "$PROPS"
    grep -q 'db.mongo.wiredTigerCacheSizeGB' "$PROPS" || \
      echo 'db.mongo.wiredTigerCacheSizeGB=0.5' >> "$PROPS"
  '';
}

{ pkgs, ... }: {
  services.unifi = {
    enable = true;
    openFirewall = false;
    mongodbPackage = pkgs.mongodb-ce;
  };
}

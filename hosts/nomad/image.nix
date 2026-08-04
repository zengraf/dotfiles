{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  # Legacy MBR because DigitalOcean cannot boot UEFI, uncompressed raw because
  # Vultr accepts nothing else. Deterministic so the output hash identifies the
  # node config.
  system.build.nomadImage = import (modulesPath + "/../lib/make-disk-image.nix") {
    inherit config lib pkgs;
    name = "nomad-image";
    baseName = "nomad";
    format = "raw";
    partitionTableType = "legacy";
    diskSize = "auto";
    additionalSpace = "256M";
    copyChannel = false;
    deterministic = true;
    label = "nixos";
  };
}

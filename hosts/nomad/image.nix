{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  # MBR/legacy, because DigitalOcean custom images cannot boot UEFI. Uncompressed
  # raw, because Vultr accepts raw only. `deterministic` makes the output store
  # hash a stable identity for the node config — `up` compares it against the
  # published snapshot and refuses to provision a stale one.
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

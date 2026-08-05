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
    # Slack on top of the closure. The node keeps no state worth the name: logs
    # are volatile, /tmp is tmpfs, and tailscale's state is a few hundred KB.
    additionalSpace = "32M";
    copyChannel = false;
    deterministic = true;
    label = "nixos";
  };
}

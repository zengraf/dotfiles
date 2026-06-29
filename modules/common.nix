{
  pkgs,
  lib,
  hostname,
  username ? null,
  ...
}:
{
  nix.package = pkgs.lixPackageSets.stable.lix;
  nix.settings = {
    experimental-features = "nix-command flakes";
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://virby-nix-darwin.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "virby-nix-darwin.cachix.org-1:z9GiEZeBU5bEeoDQjyfHPMGPBaIQJOOvYOOjGMKIlLo="
    ];
    builders-use-substitutes = true;
    connect-timeout = 5;
    stalled-download-timeout = 20;
    download-attempts = 2;
    trusted-users = lib.optionals (username != null) [ username ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import ../overlays/graphify.nix)
    (import ../overlays/lix-packages.nix)
    (import ../overlays/openconnect.nix)
  ];

  networking.hostName = hostname;

  security.pki.certificateFiles = [ ../pki/ca.crt ];

  environment.systemPackages = with pkgs; [
    cachix
    coreutils
    nixos-rebuild
    vim
    wget
  ];
}

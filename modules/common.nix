{ pkgs, hostname, ... }: {
  nix.package = pkgs.lixPackageSets.stable.lix;
  nix.settings = {
    experimental-features = "nix-command flakes";
    substituters = [ "https://zengraf.cachix.org" ];
    trusted-public-keys = [ "zengraf.cachix.org-1:NhxoewsqkPaN9Tp8Q0A5XR0+bgwj4JM8atN8cfq87PI=" ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ (import ../overlays/lix-packages.nix) ];

  networking.hostName = hostname;

  security.pki.certificateFiles = [ ../pki/ca.crt ];

  environment.systemPackages = with pkgs; [ cachix nixos-rebuild vim wget ];
}

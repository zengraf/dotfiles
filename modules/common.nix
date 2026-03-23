{ pkgs, hostname, ... }: {
  nix.settings = {
    package = pkgs.lix;
    experimental-features = "nix-command flakes";
    substituters = [ "https://zengraf.cachix.org" ];
    trusted-public-keys = [ "zengraf.cachix.org-1:NhxoewsqkPaN9Tp8Q0A5XR0+bgwj4JM8atN8cfq87PI=" ];
  };

  nixpkgs.config.allowUnfree = true;

  networking.hostName = hostname;

  security.pki.certificateFiles = [ ../pki/ca.crt ];

  environment.systemPackages = with pkgs; [ vim wget ];
}

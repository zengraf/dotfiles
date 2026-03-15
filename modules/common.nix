{ pkgs, ... }: {
  nix.settings = {
    experimental-features = "nix-command flakes";
    substituters = [ "https://zengraf.cachix.org" ];
    trusted-public-keys = [ "zengraf.cachix.org-1:NhxoewsqkPaN9Tp8Q0A5XR0+bgwj4JM8atN8cfq87PI=" ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ vim wget ];
}

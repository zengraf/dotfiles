{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
    ../../modules/nixos/router.nix
    ../../modules/nixos/kea.nix
    ../../modules/nixos/unbound.nix
    ../../modules/nixos/tailscale.nix
    ../../modules/nixos/unifi.nix
  ];

  networking.hostName = "router";

  environment.systemPackages = with pkgs; [
    tcpdump
    ethtool
    iperf3
  ];

  system.stateVersion = "25.11";
}

{ pkgs, username, ... }: {
  nixpkgs.overlays = [ (import ../../overlays/mongodb-no-avx.nix) ];
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/tailscale.nix
    ./router.nix
    ./kea.nix
    ./unbound.nix
    ./unifi.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "router";
  networking.useNetworkd = true;
  networking.networkmanager.enable = false;
  networking.nftables.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  time.timeZone = "Europe/Warsaw";

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAUexCVcDyovTWhCWmOpSwaeXS5MnfPHhJgVaaEXWJSp"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  home-manager.users.${username} = ./home.nix;

  environment.systemPackages = with pkgs; [
    tcpdump
    ethtool
    iperf3
  ];

  system.stateVersion = "25.11";
}

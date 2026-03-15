{ ... }: {
  networking.useNetworkd = true;
  networking.networkmanager.enable = false;

  networking.nftables.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  time.timeZone = "Europe/Warsaw";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAUexCVcDyovTWhCWmOpSwaeXS5MnfPHhJgVaaEXWJSp"
  ];
}

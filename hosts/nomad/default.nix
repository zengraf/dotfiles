{
  config,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./image.nix
  ];

  boot = {
    # No growPartition: it pulls cloud-utils and with it all of python3, for
    # 135 MB, to enlarge a root filesystem a stateless node never fills.
    initrd.systemd.enable = true;
    kernelParams = [
      "console=ttyS0"
      "panic=1"
      "boot.panic_on_fail"
    ];
    initrd.kernelModules = [ "virtio_scsi" ];
    kernelModules = [
      "virtio_pci"
      "virtio_net"
    ];
    loader = {
      timeout = 0;
      grub = {
        enable = true;
        device = "/dev/vda";
        efiSupport = false;
      };
    };

    kernel.sysctl = {
      # The tailscale module only relaxes RPF for "client"/"both", so a
      # server-mode exit node would still drop forwarded packets.
      "net.ipv4.conf.all.rp_filter" = 2;
      "net.ipv4.conf.default.rp_filter" = 2;

      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.core.netdev_max_backlog" = 8192;
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  networking = {
    hostName = "nomad";
    useNetworkd = true;
    useDHCP = false;

    firewall = {
      enable = true;
      checkReversePath = "loose";
      trustedInterfaces = [ config.services.tailscale.interfaceName ];
    };
  };

  systemd.network.networks."10-wan" = {
    matchConfig.Name = "en* eth*";
    networkConfig = {
      DHCP = "yes";
      IPv6AcceptRA = true;
    };
    linkConfig.RequiredForOnline = "routable";
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    openFirewall = true;
  };

  # user-data is JSON: {"authkey": "tskey-...", "hostname": "nomad-in-a3f9"}
  systemd.services.nomad-join = {
    description = "Join the tailnet as an ephemeral exit node";
    wantedBy = [ "multi-user.target" ];
    requires = [ "tailscaled.service" ];
    after = [ "tailscaled.service" ];
    path = [
      pkgs.curl
      pkgs.jq
      config.services.tailscale.package
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail

      user_data=""
      for attempt in $(seq 1 30); do
        for url in \
          http://169.254.169.254/v1/user-data \
          http://169.254.169.254/metadata/v1/user-data \
          http://169.254.169.254/latest/user-data
        do
          if user_data=$(curl -fsS --max-time 3 "$url" 2>/dev/null) \
            && jq -e . >/dev/null 2>&1 <<<"$user_data"; then
            break 2
          fi
        done
        user_data=""
        sleep 1
      done

      if [ -z "$user_data" ]; then
        echo "no usable user-data from the metadata service" >&2
        exit 1
      fi

      authkey=$(jq -er .authkey <<<"$user_data")
      hostname=$(jq -er .hostname <<<"$user_data")

      tailscale up \
        --auth-key="$authkey" \
        --hostname="$hostname" \
        --advertise-exit-node \
        --accept-dns=false \
        --ssh
    '';
  };

  systemd.services.nomad-nic-offload = {
    description = "Tune NIC offload for forwarded UDP";
    wantedBy = [ "multi-user.target" ];
    after = [ "nomad-join.service" ];
    path = [
      pkgs.ethtool
      pkgs.iproute2
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      dev=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
      ethtool -K "$dev" rx-udp-gro-forwarding on rx-gro-list off
    '';
  };

  # The two activation scripts that need perl: /etc assembly and user creation.
  # An overlay mount and systemd-sysusers replace both, and perl's 55 MB with it.
  system.etc.overlay.enable = true;
  systemd.sysusers.enable = true;

  documentation.enable = false;
  documentation.nixos.enable = false;
  environment.defaultPackages = [ ];
  services.udisks2.enable = false;
  nix.enable = false;

  # Nothing here rebuilds itself, runs containers, or renders a document.
  system.disableInstallerTools = true;
  boot.enableContainers = false;
  programs.command-not-found.enable = false;
  systemd.coredump.enable = false;
  services.logrotate.enable = false;
  environment.stub-ld.enable = false;
  xdg.icons.enable = false;
  xdg.mime.enable = false;
  xdg.sounds.enable = false;
  fonts.fontconfig.enable = false;

  # No password and no authorized key: network ingress is Tailscale SSH only.
  users.mutableUsers = false;
  users.allowNoPasswordLogin = true;

  # Autologin on the serial console. Reachable only through the provider's panel,
  # which already implies control of the instance, and it is the sole way to
  # diagnose a node that fails to join the tailnet: without it a failed join
  # leaves a box nobody can enter.
  services.getty.autologinUser = "root";

  system.stateVersion = "25.11";
}

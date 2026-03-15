{ ... }: {
  services.tailscale.useRoutingFeatures = "both";
  services.tailscale.extraSetFlags = [
    "--advertise-exit-node"
    "--advertise-routes=172.16.0.0/12"
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;

    # Socket buffers — 32MB for 2.5G throughput
    "net.core.rmem_max" = 33554432;
    "net.core.wmem_max" = 33554432;
    "net.core.rmem_default" = 1048576;
    "net.core.wmem_default" = 1048576;
    "net.ipv4.tcp_rmem" = "4096 131072 33554432";
    "net.ipv4.tcp_wmem" = "4096 131072 33554432";
    "net.ipv4.udp_rmem_min" = 8192;
    "net.ipv4.udp_wmem_min" = 8192;

    # Queues and backlog
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    "net.core.optmem_max" = 65536;

    # TCP performance
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_mtu_probing" = 1;

    # Conntrack — sized for home NAT
    "net.netfilter.nf_conntrack_max" = 262144;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 7200;

    # GC for neighbor table (ARP)
    "net.ipv4.neigh.default.gc_thresh1" = 2048;
    "net.ipv4.neigh.default.gc_thresh2" = 4096;
    "net.ipv4.neigh.default.gc_thresh3" = 8192;
  };

  systemd.network.networks = {
    "10-wan" = {
      matchConfig.Name = "enp1s0";
      networkConfig = {
        DHCP = "ipv4";
      };
      dhcpV4Config = {
        UseDNS = false;
      };
    };
    "10-lan" = {
      matchConfig.Name = "enp2s0";
      networkConfig = {
        Address = "172.20.0.1/12";
      };
    };
  };

  networking.firewall.enable = false;

  networking.nftables.ruleset = ''
    table inet filter {
      chain input {
        type filter hook input priority 0; policy drop;

        iifname "lo" accept
        ct state { established, related } accept

        # Allow DHCP, DNS, and SSH on LAN
        iifname "enp2s0" udp dport { 53, 67 } accept
        iifname "enp2s0" tcp dport { 53, 22 } accept

        # Allow Unifi controller on LAN
        iifname "enp2s0" tcp dport { 8080, 8443, 6789 } accept
        iifname "enp2s0" udp dport { 3478, 10001, 10101, 1900 } accept

        # Allow Tailscale
        udp dport 41641 accept
        iifname "tailscale0" accept

        # ICMPv4
        icmp type { echo-request, destination-unreachable, time-exceeded } accept
      }

      chain forward {
        type filter hook forward priority 0; policy drop;

        ct state { established, related } accept

        # LAN → WAN
        iifname "enp2s0" oifname "enp1s0" accept

        # Tailscale ↔ LAN
        iifname "tailscale0" oifname "enp2s0" accept
        iifname "enp2s0" oifname "tailscale0" accept

        # Tailscale → WAN (exit node)
        iifname "tailscale0" oifname "enp1s0" accept
      }
    }

    table inet nat {
      chain postrouting {
        type nat hook postrouting priority 100;

        oifname "enp1s0" masquerade
      }
    }
  '';
}

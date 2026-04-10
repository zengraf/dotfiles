{ ... }: {
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [ "172.20.0.1" "127.0.0.1" "100.126.112.1" ];
        access-control = [
          "127.0.0.0/8 allow"
          "172.16.0.0/12 allow"
          "100.64.0.0/10 allow"
        ];
        tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";
        extended-statistics = true;

        msg-cache-size = "50m";
        rrset-cache-size = "100m";
        cache-min-ttl = 300;
        cache-max-ttl = 86400;
        neg-cache-ttl = 3600;
        prefetch = true;
        prefetch-key = true;
        outgoing-num-tcp = 10;

        local-zone = [ "zengraf.arpa. static" ];
        local-data = [
          ''"router.zengraf.arpa. A 172.20.0.1"''
          ''"dashboard.zengraf.arpa. A 172.20.0.1"''
          ''"unifi.zengraf.arpa. A 172.20.0.1"''
        ];
      };
      remote-control = {
        control-enable = true;
        control-interface = "/run/unbound/unbound.ctl";
      };
      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = true;
          forward-addr = [
            "1.1.1.1@853#cloudflare-dns.com"
            "1.0.0.1@853#cloudflare-dns.com"
            "9.9.9.9@853#dns.quad9.net"
          ];
        }
      ];
    };
  };
}

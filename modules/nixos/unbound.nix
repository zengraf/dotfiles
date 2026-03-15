{ ... }: {
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [ "172.20.0.1" "127.0.0.1" ];
        access-control = [
          "127.0.0.0/8 allow"
          "172.16.0.0/12 allow"
        ];
        tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";

        local-zone = [ "zengraf.arpa. static" ];
        local-data = [
          ''"router.zengraf.arpa. A 172.20.0.1"''
        ];
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

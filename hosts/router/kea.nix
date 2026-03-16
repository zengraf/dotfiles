{ ... }: {
  services.kea.ctrl-agent = {
    enable = true;
    settings = {
      http-host = "127.0.0.1";
      http-port = 14461;
      control-sockets.dhcp4 = {
        socket-type = "unix";
        socket-name = "/run/kea/kea-dhcp4.socket";
      };
    };
  };

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "enp2s0" ];
      };
      control-socket = {
        socket-type = "unix";
        socket-name = "/run/kea/kea-dhcp4.socket";
      };
      lease-database = {
        type = "memfile";
        persist = true;
        lfc-interval = 3600;
      };
      valid-lifetime = 43200; # 12 hours
      subnet4 = [
        {
          id = 1;
          subnet = "172.16.0.0/12";
          pools = [
            { pool = "172.20.1.0 - 172.20.255.254"; }
          ];
          option-data = [
            { name = "routers"; data = "172.20.0.1"; }
            { name = "domain-name-servers"; data = "172.20.0.1"; }
          ];
          reservations = [
            # Example static lease — add your devices here:
            # {
            #   hw-address = "aa:bb:cc:dd:ee:ff";
            #   ip-address = "172.20.0.10";
            #   hostname = "unifi-ap";
            # }
          ];
        }
      ];
    };
  };
}

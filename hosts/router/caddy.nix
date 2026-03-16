{ config, helpers, ... }:
let
  inherit (helpers) formatAddress;
  grafana = config.services.grafana.settings.server;
  caddy = config.services.caddy;
in
{
  age.secrets.ca-key = {
    file = ../../secrets/ca-key.age;
    owner = caddy.user;
    group = caddy.group;
  };

  services.caddy = {
    enable = true;
    globalConfig = ''
      pki {
        ca local {
          name "Zengraf LAN CA"
          root {
            cert ${../../pki/ca.crt}
            key ${config.age.secrets.ca-key.path}
          }
          install_trust false
        }
      }
    '';
    virtualHosts = {
      "dashboard.zengraf.arpa" = {
        extraConfig = ''
          tls {
            issuer internal { ca local }
          }
          reverse_proxy ${formatAddress grafana.http_addr grafana.http_port}
        '';
      };
      "unifi.zengraf.arpa" = {
        extraConfig = ''
          tls {
            issuer internal { ca local }
          }
          reverse_proxy https://localhost:8443 {
            transport http {
              tls_insecure_skip_verify
            }
          }
        '';
      };
    };
  };
}

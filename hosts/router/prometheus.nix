{ pkgs, config, helpers, ... }:
let
  inherit (helpers) formatAddress;
  unbound = config.services.unbound;
  exporters = config.services.prometheus.exporters;
  keaAgent = config.services.kea.ctrl-agent.settings;
in
{
  age.secrets.unpoller-password = {
    file = ../../secrets/unpoller-password.age;
    owner = "unifi-poller";
    group = "unifi-poller";
  };

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "30d";

    exporters = {
      node = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9100;
        enabledCollectors = [ "systemd" "conntrack" ];
      };

      unbound = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9167;
        unbound.host = unbound.settings.remote-control.control-interface;
        group = unbound.group;
      };

      kea = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9547;
        targets = [ "http://${formatAddress keaAgent.http-host keaAgent.http-port}" ];
      };

      blackbox = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9115;
        configFile = pkgs.writeText "blackbox.yml" (builtins.toJSON {
          modules = {
            icmp = {
              prober = "icmp";
              timeout = "5s";
            };
            dns_resolve = {
              prober = "dns";
              timeout = "5s";
              dns = {
                query_name = "cloudflare.com";
                query_type = "A";
              };
            };
          };
        });
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{ targets = [ (formatAddress exporters.node.listenAddress exporters.node.port) ]; }];
      }
      {
        job_name = "unbound";
        static_configs = [{ targets = [ (formatAddress exporters.unbound.listenAddress exporters.unbound.port) ]; }];
      }
      {
        job_name = "kea";
        static_configs = [{ targets = [ (formatAddress exporters.kea.listenAddress exporters.kea.port) ]; }];
      }
      {
        job_name = "unpoller";
        static_configs = [{ targets = [ config.services.unpoller.prometheus.http_listen ]; }];
      }
      {
        job_name = "blackbox-icmp";
        metrics_path = "/probe";
        params.module = [ "icmp" ];
        static_configs = [{ targets = [ "1.1.1.1" "9.9.9.9" "172.20.0.1" ]; }];
        relabel_configs = [
          { source_labels = [ "__address__" ]; target_label = "__param_target"; }
          { source_labels = [ "__param_target" ]; target_label = "instance"; }
          { target_label = "__address__"; replacement = formatAddress exporters.blackbox.listenAddress exporters.blackbox.port; }
        ];
      }
      {
        job_name = "blackbox-dns";
        metrics_path = "/probe";
        params.module = [ "dns_resolve" ];
        static_configs = [{ targets = [ "1.1.1.1" "9.9.9.9" "172.20.0.1" ]; }];
        relabel_configs = [
          { source_labels = [ "__address__" ]; target_label = "__param_target"; }
          { source_labels = [ "__param_target" ]; target_label = "instance"; }
          { target_label = "__address__"; replacement = formatAddress exporters.blackbox.listenAddress exporters.blackbox.port; }
        ];
      }
    ];
  };

  services.unpoller = {
    enable = true;
    influxdb.disable = true;
    prometheus = {
      http_listen = "127.0.0.1:9130";
      report_errors = true;
    };
    unifi = {
      dynamic = false;
      defaults = {
        url = "https://localhost:8443";
        user = "unpoller";
        pass = config.age.secrets.unpoller-password.path;
        verify_ssl = false;
        save_sites = true;
        save_dpi = true;
      };
    };
  };
}

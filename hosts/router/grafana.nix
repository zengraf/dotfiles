{ config, ... }: {
  age.secrets.grafana-secret-key = {
    file = ../../secrets/grafana-secret-key.age;
    owner = "grafana";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "dashboard.zengraf.arpa";
        root_url = "https://dashboard.zengraf.arpa";
      };
      security = {
        admin_user = "admin";
        admin_password = "admin";
        secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:9090";
          isDefault = true;
          editable = false;
        }
      ];
    };
  };
}

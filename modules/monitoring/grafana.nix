{ config, pkgs, ... }:
let
  portNumber = 2342;
in
{
  # grafana configuration
  services.grafana = {
    enable = true;
    settings.server = {
      http_port = portNumber;
      http_addr = "127.0.0.1";
    };
    settings.security.secret_key = "$__file{${config.sops.secrets.grafana.path}}";
    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString config.services.prometheus.port}";
            uid = "prometheus";
            isDefault = true;
            editable = false;
          }
        ];
      };
    };
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "grafana";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];

  sops.secrets.grafana = {
    sopsFile = ./grafana.bin;
    format = "binary";
    owner = "grafana";
    mode = "0400";
    restartUnits = [ "grafana.service" ];
  };
}

{ config, pkgs, ... }:
let
  portNumber = 9001;
in
{
  # https://wiki.nixos.org/wiki/Prometheus
  # https://nixos.org/manual/nixos/stable/#module-services-prometheus-exporters-configuration
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/default.nix
  services.prometheus = {
    enable = true;
    port = portNumber;
    globalConfig.scrape_interval = "10s";
    globalConfig.evaluation_interval = "10s";
    checkConfig = "syntax-only";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
            labels.host = config.networking.hostName;
          }
        ];
      }
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString portNumber}" ];
            labels.host = config.networking.hostName;
          }
        ];
      }
      {
        job_name = "homeassistant";
        metrics_path = "/api/prometheus";
        authorization = {
          type = "Bearer";
          credentials_file = config.sops.secrets.homeassistantPrometheusToken.path;
        };
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.home-assistant.config.http.server_port}" ];
            labels.host = config.networking.hostName;
          }
        ];
      }
      {
        job_name = "smartctl";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}" ];
            labels.host = config.networking.hostName;
          }
        ];
      }
    ];
  };

  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "prometheus";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}

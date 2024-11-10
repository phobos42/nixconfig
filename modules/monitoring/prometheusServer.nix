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
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          { targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ]; }
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

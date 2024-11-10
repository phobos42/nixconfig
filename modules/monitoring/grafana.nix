{ config, pkgs, ... }:
let
  portNumber = 2342;
in
{
  # grafana configuration
  services.grafana = {
    enable = true;
    # domain = "grafana.tailnethome.garrettruffner.com";
    port = portNumber;
    addr = "127.0.0.1";
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "grafana";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}

{ config, ... }:
let portNumber = 6052;
in {
  services.esphome = {
    enable = true;
    port = portNumber;
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [{
    name = "esphome";
    value = { url = "http://127.0.0.1:${toString portNumber}"; };
  }];
}

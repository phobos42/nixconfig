# { pkgs-unstable, ... }:
# let portNumber = 9090;
# in {
#   services.cockpit = {
#     package = pkgs-unstable.cockpit;
#     enable = true;
#     port = portNumber;
#     settings = {
#       "WebService" = {
#         Origins =
#           "https://cockpit.home.garrettruffner.com https://cockpit.tailnethome.garrettruffner.com";
#       };
#     };
#   };
#   services.traefik-wrapper.service-definitions = builtins.listToAttrs [{
#     name = "cockpit";
#     value = { url = "http://127.0.0.1:${toString portNumber}"; };
#   }];
# }
{ pkgs-unstable, config, ... }:
let
  portNumber = 9090;
  cfg = config.services.traefik-wrapper;
in {
  services.cockpit = {
    package = pkgs-unstable.cockpit;
    enable = true;
    port = portNumber;
    allowed-origins = 
      builtins.map (subdomain:
        ''https://cockpit.${subdomain}.${cfg.base-domain}'')
        cfg.domain-subnets;
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [{
    name = "cockpit";
    value = { url = "http://127.0.0.1:${toString portNumber}"; };
  }];
}
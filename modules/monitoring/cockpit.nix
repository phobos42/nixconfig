{ pkgs-unstable, config, lib, ... }:
let
  portNumber = 9090;
  serviceHostname = "cockpit-${lib.strings.toLower config.networking.hostName}";
in {
  services.cockpit = {
    package = pkgs-unstable.cockpit;
    enable = true;
    port = portNumber;
  };
  sops.templates."cockpit/cockpit.conf" = {
    content = ''
      [WebService]
      Origins = https://${serviceHostname}.${config.sops.placeholder.base_domain}
      LoginTo = false
    '';
    mode = "0444";
  };
  systemd.services = {
    "cockpit-wsinstance-http".environment.XDG_CONFIG_DIRS = "/run/secrets/rendered";
    "cockpit-wsinstance-https@".environment.XDG_CONFIG_DIRS = "/run/secrets/rendered";
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [{
    name = "cockpit";
    value = {
      hostname = serviceHostname;
      url = "http://127.0.0.1:${toString portNumber}";
    };
  }];
}

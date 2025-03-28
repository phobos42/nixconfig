{ pkgs, ... }:
let
  portNumber = 1398;
in
{
  services.open-webui = {
    package = pkgs.open-webui;
    enable = true;
    port = portNumber;
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "openwebui";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}

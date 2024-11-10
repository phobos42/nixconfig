{ ... }:
let
  portNumber = 9090;
in
{
  services.cockpit = {
    enable = true;
    port = portNumber;
    settings = {
      "WebService" = {
        Origins = "https://cockpit.home.garrettruffner.com https://cockpit.tailnethome.garrettruffner.com";
      };
    };
  };
    services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "cockpit";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}

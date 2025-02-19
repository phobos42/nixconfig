{ pkgs-unstable, ... }:
let
  portNumber = 9117;
in
{
  services.jackett = {
    package = pkgs-unstable.jackett;
    enable = true;
  };

  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "jackett";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
  services.flaresolverr = {
    enable = true;
    
  };
}



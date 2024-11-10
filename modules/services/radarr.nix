{ ... }:
let
  portNumber = 7878;
in
{
  services.radarr = {
    enable = true;
  };
  #7878
  users.users.radarr.extraGroups = [ "media" ];

  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "radarr";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}

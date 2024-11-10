{ ... }:
let
  portNumber = 8096;
in
{
  services.jellyfin.enable = true;
  users.users.jellyfin.extraGroups = [ "media" ];

  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "jellyfin";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}

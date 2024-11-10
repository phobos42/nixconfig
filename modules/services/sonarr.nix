{ ... }:
let
  portNumber = 8989;
in
{
  services.sonarr = {
    # Port 8989
    enable = true;
    # openFirewall = true;
  };
  users.users.sonarr.extraGroups = [ "media" ];

    services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "sonarr";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}

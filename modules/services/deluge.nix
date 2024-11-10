{ ... }:
let
  portNumber = 8112;
in
{
  services.deluge = {
    enable = true;
    web = {
      enable = true;
      port = portNumber;
    };
  };
  users.users.deluge.extraGroups = [ "media" ];

  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "deluge";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}

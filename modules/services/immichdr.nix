{ pkgs, ... }:
let
  portNumber = 2283;
in
{
  services.immich = {
    package = pkgs.immich;
    user = "immich";
    group = "immich";
    enable = true;
    port = portNumber;
    settings  = {};
    mediaLocation = "/tank/dr/immich/";
    database = {
      enable = true;
      createDB = true;
    };
  };
  services.postgresql = {
    enable = true;
    # Ensure the database, user, and permissions always exist
    dataDir = "/tank/dr/services/drpsdb";
    ensureDatabases = [ "immich" ];
    ensureUsers = [
      {
        name = "immich";
        ensureDBOwnership = true;
      }
    ];
  };
  systemd.services."immich" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "immich";
      value = {
        url = "http://localhost:${toString portNumber}";
      };
    }
  ];
}

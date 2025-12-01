{ config, lib, ... }:
let
  BaseDirectory = "/tank/dr/vaultwarden/";
  DataDirectory = "data";
  BackupDirectory = "backup";
  portNumber = 8222;
in
{
  services.vaultwarden = {
    enable = true;
    environmentFile = "${config.sops.secrets.vaultwarden.path}";
    # backupDir = "${BaseDirectory}${BackupDirectory}";
    config = {
      DOMAIN = "https://vaultwarden.perdido.garrettruffner.com";
      SIGNUPS_ALLOWED = true;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = portNumber;
      ROCKET_LOG = "info";
      RO_MODE = true;
      # DATA_FOLDER = "${BaseDirectory}${DataDirectory}";
    };
  };
  # systemd.services.backup-vaultwarden.environment.DATA_FOLDER = lib.mkForce "${BaseDirectory}${DataDirectory}";
  users.users.vaultwarden.extraGroups = [ "secure" ];
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "vaultwarden";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
  sops.secrets = {
    vaultwarden = {
      sopsFile = ./vaultwarden.env;
      format = "dotenv";
      restartUnits = [ "vaultwarden" ];
    };
  };
}

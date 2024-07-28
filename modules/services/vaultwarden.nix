{ lib, ... }:
let
  BaseDirectory = "/tank/shack/cloud/vaultwarden/";
  DataDirectory = "data";
  BackupDirectory = "backup";
in
{
  services.vaultwarden = {
    enable = true;
    environmentFile = "/var/vaultwarden-admin";
    backupDir = "${BaseDirectory}${BackupDirectory}";
    config = {
      DOMAIN = "https://vaultwarden.tailnethome.garrettruffner.com";
      SIGNUPS_ALLOWED = true;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "info";
      # DATA_FOLDER = "${BaseDirectory}${DataDirectory}";
    };
  };
  # systemd.services.backup-vaultwarden.environment.DATA_FOLDER = lib.mkForce "${BaseDirectory}${DataDirectory}";
  users.users.vaultwarden.extraGroups = [ "secure" ];
}

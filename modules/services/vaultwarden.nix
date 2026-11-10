{ config, ... }:
let
  BaseDirectory = "/tank/shack/cloud/vaultwarden/";
  BackupDirectory = "backup";
  portNumber = 8222;
in
{
  services.vaultwarden = {
    enable = true;
    environmentFile = [
      config.sops.secrets.vaultwarden.path
      config.sops.templates."vaultwarden-domain.env".path
    ];
    backupDir = "${BaseDirectory}${BackupDirectory}";
    config = {
      SIGNUPS_ALLOWED = true;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = portNumber;
      ROCKET_LOG = "info";
      # DATA_FOLDER = "${BaseDirectory}${DataDirectory}";
    };
  };
  sops.templates."vaultwarden-domain.env".content = ''
    DOMAIN=https://vaultwarden.${config.sops.placeholder.base_domain}
  '';
  # systemd.services.backup-vaultwarden.environment.DATA_FOLDER = lib.mkForce "${BaseDirectory}${DataDirectory}";
  users.users.vaultwarden.extraGroups = [ "secure" ];
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "vaultwarden";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
        public = true;
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

{ pkgs, ... }:
{
  # Force nextcloud to listed on port 8081 internally for traefik to take port 80+443
  services.nginx = {
    enable = true;
    virtualHosts = {
      "nextcloud.home.garrettruffner.com" = {
        listen = [{ addr = "127.0.0.1"; port = 8081; }];
        locations."/*".proxyPass = "http://127.0.0.1:8081";
      };
    };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28;
    hostName = "nextcloud.home.garrettruffner.com";
    home = "/tank/shack/cloud/nextcloud/nextcloudconfig";
    datadir = "/tank/shack/cloud/nextcloud/nextcloudstorage";

    # Auto-update Nextcloud Apps
    autoUpdateApps.enable = true;
    autoUpdateApps.startAt = "05:00:00";

    settings = {
      overwriteprotocol = "https";
      trusted_domains = [
        "nextcloud.tailnethome.garrettruffner.com"
      ];
    };

    config = {
      # Nextcloud PostegreSQL database configuration
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
      dbname = "nextcloud";
      dbpassFile = "/tank/shack/cloud/nextcloud/nextcloud-db-pass";
      adminpassFile = "/tank/shack/cloud/nextcloud/nextcloud-admin-pass";
      adminuser = "admin";

    };
  };
  services.postgresql = {
    enable = true;
    # Ensure the database, user, and permissions always exist
    dataDir = "/tank/services/nextcloudpsdb";
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
    ];
  };
  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
}

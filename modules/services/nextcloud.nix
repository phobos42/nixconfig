{ pkgs, lib, config, ... }:
let
  portNumber = 8081;
in
{
  # Force nextcloud to listed on port 8081 internally for traefik to take port 80+443
  services.nginx = {
    enable = true;
    virtualHosts = {
      "nextcloud.home.garrettruffner.com" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = portNumber;
          }
        ];
        locations."/*".proxyPass = "http://127.0.0.1:${toString portNumber}";
      };
    };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud34;
    hostName = "nextcloud.home.garrettruffner.com";
    home = "/tank/shack/cloud/nextcloud/nextcloudconfig";
    datadir = "/tank/shack/cloud/nextcloud/nextcloudstorage";

    # Auto-update Nextcloud Apps
    autoUpdateApps.enable = true;
    autoUpdateApps.startAt = "05:00:00";

    settings = {
      # overwriteprotocol = "https";
      # overwritehost = "nextcloud.garrettstuff.duckdns.org";
      # overwrite.cli.url = "https://nextcloud.garrettstuff.duckdns.org";
      # trusted_proxies = [ "100.74.249.16" ];
      # overwritecond.address = "^100\\.74\\.249\\.16$";
      # trusted_domains = [ "nextcloud.garrettstuff.duckdns.org" "nextcloud.tailnethome.garrettruffner.com" ];
      "trusted_domains" = [
        "nextcloud.garrettstuff.duckdns.org"
        "nextcloud.tailnethome.garrettruffner.com"
      ];

      "trusted_proxies" = [
        "172.234.30.101"
        "100.74.249.16"
      ];

      "overwriteprotocol" = "https";
      "overwritehost" = "nextcloud.tailnethome.garrettruffner.com";
      "overwrite.cli.url" = "https://nextcloud.garrettstuff.duckdns.org";

      "overwritecond.address" = "^172\\.234\\.30\\.101$";
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
    appstoreEnable = true;
    extraAppsEnable = true;
    extraApps = with config.services.nextcloud.package.packages.apps; {
      inherit
        # ... other apps
        richdocuments # Collabora Online for Nextcloud - https://apps.nextcloud.com/apps/richdocuments
        ;
    };
  };

#   systemd.services.nextcloud = {
#     serviceConfig = {
#       EnvironmentFile = [ config.sops.secrets.urlconfig.path ];
#     };
#     preStart = ''
#       install -d -m 0755 "${config.services.nextcloud.home}/config"
#       cat > "${config.services.nextcloud.home}/config/override.config.php" <<'PHP'
# <?php
# $CONFIG['overwritehost'] = 'nextcloud.' . getenv('PUBLIC_DOMAIN1');
# $CONFIG['overwrite.cli.url'] = 'https://nextcloud.' . getenv('PUBLIC_DOMAIN1');
# $CONFIG['trusted_domains'] = array_values(array_unique(array_merge(
#   $CONFIG['trusted_domains'] ?? [],
#   [
#     'nextcloud.tailnethome.garrettruffner.com',
#     'nextcloud.' . getenv('PUBLIC_DOMAIN1'),
#   ]
# )));
# PHP
#     '';
#   };

  systemd.services."nextcloud-setup".serviceConfig = {
    EnvironmentFile = [ config.sops.secrets.urlconfig.path ];
  };

  sops.secrets = {
    urlconfig = {
      sopsFile = ./urlconfig.env;
      format = "dotenv";
      restartUnits = [ "nextcloud.service" ];
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
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "nextcloud";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
  # services.prometheus.exporters.nextcloud = {
  #   enable = true;
  # };
}

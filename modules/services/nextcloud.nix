{ pkgs, lib, config, ... }:
let
  portNumber = 8081;
in
{
  # Force nextcloud to listed on port 8081 internally for traefik to take port 80+443
  services.nginx = {
    enable = true;
    virtualHosts = {
      "localhost" = {
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
    hostName = "localhost";
    home = "/tank/shack/cloud/nextcloud/nextcloudconfig";
    datadir = "/tank/shack/cloud/nextcloud/nextcloudstorage";

    # Auto-update Nextcloud Apps
    autoUpdateApps.enable = true;
    autoUpdateApps.startAt = "05:00:00";

    settings = {
      "trusted_domains" = [
        "localhost"
      ];

      "trusted_proxies" = [ "127.0.0.1" ];

      "overwriteprotocol" = "https";
      "overwritehost" = "localhost";
      "overwrite.cli.url" = "http://localhost";
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
  systemd.services.nextcloud = {
    serviceConfig.EnvironmentFile = config.sops.templates."base-domain.env".path;
    preStart = lib.mkAfter ''
      ${config.services.nextcloud.occ}/bin/nextcloud-occ config:system:set trusted_domains 0 --value="nextcloud.''${BASE_DOMAIN}"
      ${config.services.nextcloud.occ}/bin/nextcloud-occ config:system:set overwritehost --value="nextcloud.''${BASE_DOMAIN}"
      ${config.services.nextcloud.occ}/bin/nextcloud-occ config:system:set overwriteprotocol --value=https
      ${config.services.nextcloud.occ}/bin/nextcloud-occ config:system:set overwrite.cli.url --value="https://nextcloud.''${BASE_DOMAIN}"
    '';
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "nextcloud";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
        public = true;
      };
    }
  ];
  # services.prometheus.exporters.nextcloud = {
  #   enable = true;
  # };
}

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
  sops.templates."nextcloud-public-domain.config.php" = {
    path = "${config.services.nextcloud.datadir}/config/zz-domain.config.php";
    content = ''
      <?php
      $publicHost = 'nextcloud.${config.sops.placeholder.base_domain}';
      $CONFIG['trusted_domains'] = array_values(array_unique(array_merge(
          $CONFIG['trusted_domains'] ?? [],
          [$publicHost]
      )));
      $CONFIG['overwritehost'] = $publicHost;
      $CONFIG['overwriteprotocol'] = 'https';
      $CONFIG['overwrite.cli.url'] = 'https://' . $publicHost;
    '';
    owner = "nextcloud";
    group = "nextcloud";
    mode = "0440";
    restartUnits = [ "phpfpm-nextcloud.service" ];
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
        public = true;
      };
    }
  ];
  # services.prometheus.exporters.nextcloud = {
  #   enable = true;
  # };
}

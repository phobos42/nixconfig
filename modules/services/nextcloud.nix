{ pkgs, ... }:
{
  # security.acme = {
  #   acceptTerms = true;
  #   # Replace the email here!
  #   defaults = {
  #     email = "garrettruffner42@gmail.com";
  #   };
  # };

  # networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx = {
    enable = true;

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    # Only allow PFS-enabled ciphers with AES256
    # sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
    # Setup Nextcloud virtual host to listen on ports
    virtualHosts = {
      "nextcloud.kraken.box" = {
        ## Force HTTP redirect to HTTPS
        # forceSSL = false;
        ## LetsEncrypt
        # enableACME = false;
      };
    };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud27;
    hostName = "nextcloud.kraken.box";
    home = "/tank/shack/cloud/nextcloud/nextcloudconfig";
    datadir = "/tank/shack/cloud/nextcloud/nextcloudstorage";

    # Auto-update Nextcloud Apps
    autoUpdateApps.enable = true;
    # Set what time makes sense for you
    autoUpdateApps.startAt = "05:00:00";

    config = {
      # Further forces Nextcloud to use HTTPS
      overwriteProtocol = "http";

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

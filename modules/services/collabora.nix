{ config, lib, ... }:
let
  portNumber = 9980;
in
{
  services.collabora-online = {
    enable = true;
    port = portNumber; # default
    settings = {
      # Rely on reverse proxy for SSL
      ssl = {
        enable = false;
        termination = true;
      };

      # Listen on loopback interface only, and accept requests from ::1
      net = {
        listen = "loopback";
        post_allow.host = ["::1"];
      };

      # Restrict loading documents from WOPI Host nextcloud.example.com
      storage.wopi = {
        "@allow" = true;
        host = ["nextcloud.tailnethome.garrettruffner.com"];
      };

      # Set FQDN of server
      server_name = "collabora.tailnethome.garrettruffner.com";
    };
  };

  systemd.services.nextcloud-config-collabora = let
    inherit (config.services.nextcloud) occ;

    wopi_url = "http://localhost:${toString config.services.collabora-online.port}";
    public_wopi_url = "https://collabora.tailnethome.garrettruffner.com";
    wopi_allowlist = lib.concatStringsSep "," [
      "localhost"
      "127.0.0.1"
      "::1"
    ];
  in {
    wantedBy = ["multi-user.target"];
    after = ["nextcloud-setup.service" "coolwsd.service"];
    requires = ["coolwsd.service"];
    script = ''
      ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_url --value ${lib.escapeShellArg wopi_url}
      ${occ}/bin/nextcloud-occ config:app:set richdocuments public_wopi_url --value ${lib.escapeShellArg public_wopi_url}
      ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_allowlist --value ${lib.escapeShellArg wopi_allowlist}
      ${occ}/bin/nextcloud-occ richdocuments:setup
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };

  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "collabora";
      value = {
        url = "http://localhost:${toString portNumber}";
      };
    }
  ];
}

{ config, lib, ... }:
let
  base-domain = "garrettruffner.com";

  active-domains = [
    {
      main = "home.${base-domain}";
      sans = "*.home.${base-domain}";
    }
    {
      main = "tailnethome.${base-domain}";
      sans = "*.tailnethome.${base-domain}";
    }
  ];
  serviceNames = [
    "sonarr"
    "jackett"
    "radarr"
    "deluge"
    "nextcloud"
    "jellyfin"
    "cockpit"
    "scrutiny"
    "homarr"
    "syncthing"
    "vaultwarden"
  ];

  insecureServiceValues = builtins.listToAttrs (builtins.map
    (nameVal: {
      name = "${nameVal}-insecure";
      value = {
        rule = "HostRegexp(`${nameVal}\.([A-Za-z0-9]+)\.${base-domain}`)";
        entryPoints = [ "web" ];
        service = "${nameVal}";
        middlewares = "redirect-to-https";
      };
    }
    )
    serviceNames);



  secureServiceValues = builtins.listToAttrs (builtins.map
    (nameVal: {
      name = "${nameVal}";
      value = {
        rule = "HostRegexp(`${nameVal}\.([A-Za-z0-9]+)\.${base-domain}`)";
        entryPoints = [ "websecure" ];
        service = "${nameVal}";
        tls = {
          certResolver = "letsencrypt";
          domains = active-domains;
        };
      };
    }
    )
    serviceNames);

  apivalue = builtins.listToAttrs [{
    name = "api";
    value = {
      rule = "Host(`traefik.home.garrettruffner.com`)";
      service = "api@internal";
    };
  }];
in
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  systemd.services.traefik = {
    environment = {
      CF_API_EMAIL = "garrettruffner42@gmail.com";
    };
    serviceConfig = {
      EnvironmentFile = [ "/var/route53-apikey" ];
    };
  };

  services.traefik = {
    enable = true;

    dynamicConfigOptions = {
      http.middlewares = {
        redirect-to-https.redirectscheme = {
          scheme = "https";
          permanent = true;
        };
      };
      http = {
        services = {
          homarr.loadBalancer.servers = [{ url = "http://127.0.0.1:7575"; }];
          scrutiny.loadBalancer.servers = [{ url = "http://127.0.0.1:8085"; }];
          cockpit.loadBalancer.servers = [{ url = "http://127.0.0.1:9090"; }];
          sonarr.loadBalancer.servers = [{ url = "http://127.0.0.1:8989"; }];
          jackett.loadBalancer.servers = [{ url = "http://127.0.0.1:9117"; }];
          radarr.loadBalancer.servers = [{ url = "http://127.0.0.1:7878"; }];
          deluge.loadBalancer.servers = [{ url = "http://127.0.0.1:8112"; }];
          nextcloud.loadBalancer.servers = [{ url = "http://127.0.0.1:8081"; }];
          jellyfin.loadBalancer.servers = [{ url = "http://127.0.0.1:8096"; }];
          syncthing.loadBalancer.servers = [{ url = "http://127.0.0.1:8384"; }];
          vaultwarden.loadBalancer.servers = [{ url = "http://127.0.0.1:8222"; }];
        };
        routers = lib.mkMerge [ secureServiceValues insecureServiceValues apivalue ];
      };
    };

    staticConfigOptions = {
      global = {
        checkNewVersion = true;
        sendAnonymousUsage = false;
      };
      api = {
        insecure = true;
        dashboard = true;
        debug = true;
      };

      entryPoints.websecure.address = ":443";
      entryPoints.web.address = ":80";

      certificatesResolvers = {
        letsencrypt.acme = {
          email = "garrettruffner42@gmail.com";
          storage = "/var/lib/traefik/cert.json";
          dnsChallenge = {
            provider = "route53";
            delayBeforeCheck = 60;
            resolvers = [ "1.1.1.1:53" ];
          };
        };
      };
    };
  };
}

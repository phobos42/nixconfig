{ config, lib, ... }:
let
  base-domain = "garrettruffner.com";
  active-domains = [{
    main = "home.${base-domain}";
    sans = "*.home.${base-domain}";
  }
    {
      main = "tailnethome.${base-domain}";
      sans = "*.tailnethome.${base-domain}";
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
          sonarr.loadBalancer.servers = [{ url = "http://127.0.0.1:8989"; }];
          jackett.loadBalancer.servers = [{ url = "http://127.0.0.1:9117"; }];
          radarr.loadBalancer.servers = [{ url = "http://127.0.0.1:7878"; }];
          deluge.loadBalancer.servers = [{ url = "http://127.0.0.1:8112"; }];
          nextcloud.loadBalancer.servers = [{ url = "http://127.0.0.1:8080"; }];
          jellyfin.loadBalancer.servers = [{ url = "http://127.0.0.1:8096"; }];
        };
        routers = {
          nextcloud-insecure = {
            rule = "HostRegexp(`nextcloud.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "web" ];
            service = "nextcloud";
            middlewares = "redirect-to-https";
          };
          nextcloud = {
            rule = "HostRegexp(`nextcloud.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "websecure" ];
            service = "nextcloud";
            tls = {
              certResolver = "letsencrypt";
              domains = active-domains;
            };
          };
          jellyfin-insecure = {
            rule = "HostRegexp(`jellyfin.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "web" ];
            service = "jellyfin";
            middlewares = "redirect-to-https";
          };
          jellyfin = {
            rule = "HostRegexp(`jellyfin.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "websecure" ];
            service = "jellyfin";
            tls = {
              certResolver = "letsencrypt";
              domains = active-domains;
            };
          };
          deluge-insecure = {
            rule = "HostRegexp(`deluge.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "web" ];
            service = "deluge";
            middlewares = "redirect-to-https";
          };
          deluge = {
            rule = "HostRegexp(`deluge.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "websecure" ];
            service = "deluge";
            tls = {
              certResolver = "letsencrypt";
              domains = active-domains;
            };
          };
          radarr-insecure = {
            rule = "HostRegexp(`radarr.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "web" ];
            service = "radarr";
            middlewares = "redirect-to-https";
          };
          radarr = {
            rule = "HostRegexp(`radarr.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "websecure" ];
            service = "radarr";
            tls = {
              certResolver = "letsencrypt";
              domains = active-domains;
            };
          };
          jackett-insecure = {
            rule = "HostRegexp(`jackett.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "web" ];
            service = "jackett";
            middlewares = "redirect-to-https";
          };
          jackett = {
            rule = "HostRegexp(`jackett.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "websecure" ];
            service = "jackett";
            tls = {
              certResolver = "letsencrypt";
              domains = active-domains;
            };
          };
          sonarr-insecure = {
            rule = "HostRegexp(`sonarr.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "web" ];
            service = "sonarr";
            middlewares = "redirect-to-https";
          };
          sonarr = {
            rule = "HostRegexp(`sonarr.{subdomain:[a-z]+}.${base-domain}`)";
            entryPoints = [ "websecure" ];
            service = "sonarr";
            tls = {
              certResolver = "letsencrypt";
              domains = active-domains;
            };
          };
        };
      };
    };

    staticConfigOptions = {
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };

      entryPoints.web.address = ":80";
      entryPoints.websecure.address = ":443";


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

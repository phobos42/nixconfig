{ config, lib, ... }:

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
          jackett.loadBalancer.servers = [{ url = "http://127.0.0.1:9117"; }];
          radarr.loadBalancer.servers = [{ url = "http://127.0.0.1:7878"; }];
          deluge.loadBalancer.servers = [{ url = "http://127.0.0.1:8112"; }];
          nextcloud.loadBalancer.servers = [{ url = "http://127.0.0.1:8080"; }];
          jellyfin.loadBalancer.servers = [ { url = "http://127.0.0.1:8096"; } ];
        };
        routers = {
          nextcloud-insecure = {
            rule = "Host(`nextcloud.home.garrettruffner.com`)";
            entryPoints = [ "web" ];
            service = "nextcloud";
            middlewares = "redirect-to-https";
          };
          nextcloud = {
            rule = "Host(`nextcloud.home.garrettruffner.com`)";
            entryPoints = [ "websecure" ];
            service = "nextcloud";
            tls = {
              certResolver = "letsencrypt";
              domains = [{
                main = "home.garrettruffner.com";
                sans = "*.home.garrettruffner.com";
              }];
            };            
          };
          jellyfin-insecure = {
            rule = "Host(`jellyfin.home.garrettruffner.com`)";
            entryPoints = [ "web" ];
            service = "jellyfin";
            middlewares = "redirect-to-https";
          };
          jellyfin = {
            rule = "Host(`jellyfin.home.garrettruffner.com`)";
            entryPoints = [ "websecure" ];
            service = "jellyfin";
            tls = {
              certResolver = "letsencrypt";
              domains = [{
                main = "home.garrettruffner.com";
                sans = "*.home.garrettruffner.com";
              }];
            };     
          };
          deluge-insecure = {
            rule = "Host(`deluge.home.garrettruffner.com`)";
            entryPoints = [ "web" ];
            service = "deluge";
            middlewares = "redirect-to-https";
          };
          deluge = {
            rule = "Host(`deluge.home.garrettruffner.com`)";
            entryPoints = [ "websecure" ];
            service = "deluge";
            tls = {
              certResolver = "letsencrypt";
              domains = [{
                main = "home.garrettruffner.com";
                sans = "*.home.garrettruffner.com";
              }];
            };     
          };
          radarr-insecure = {
            rule = "Host(`radarr.home.garrettruffner.com`)";
            entryPoints = [ "web" ];
            service = "radarr";
            middlewares = "redirect-to-https";
          };
          radarr = {
            rule = "Host(`radarr.home.garrettruffner.com`)";
            entryPoints = [ "websecure" ];
            service = "radarr";
            tls = {
              certResolver = "letsencrypt";
              domains = [{
                main = "home.garrettruffner.com";
                sans = "*.home.garrettruffner.com";
              }];
            };     
          };
          jackett-insecure = {
            rule = "Host(`jackett.home.garrettruffner.com`)";
            entryPoints = [ "web" ];
            service = "jackett";
            middlewares = "redirect-to-https";
          };
          jackett = {
            rule = "Host(`jackett.home.garrettruffner.com`)";
            entryPoints = [ "websecure" ];
            service = "jackett";
            tls = {
              certResolver = "letsencrypt";
              domains = [{
                main = "home.garrettruffner.com";
                sans = "*.home.garrettruffner.com";
              }];
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

{ config, lib, ... }:
let
  base-domain = "garrettruffner.com";
  domain-subnets = [
    "home2"
    "tailnethome2"
  ];

  active-domains = [
    {
      main = "home2.${base-domain}";
      sans = "*.home2.${base-domain}";
    }
    {
      main = "tailnethome2.${base-domain}";
      sans = "*.tailnethome2.${base-domain}";
    }
  ];

  serviceNames = [
    "pihole"
    "flame"
    "homeassistant"
  ];

  insecureServiceValues = builtins.listToAttrs (builtins.map
    (nameVal: {
      name = "${nameVal}-insecure";
      value = {
        rule = "HostRegexp(`${nameVal}\.([a-z]+)\.${base-domain}`)";
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
        rule = "HostRegexp(`${nameVal}\.([a-z]+)\.${base-domain}`)";
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
          pihole.loadBalancer.servers = [{ url = "http://127.0.0.1:1398"; } ];
          homeassistant.loadBalancer.servers = [{ url = "http://192.168.1.102:8123"; }];
          flame.loadBalancer.servers = [{ url = "http://127.0.0.1:5005"; }];
        };
        routers = lib.mkMerge [ secureServiceValues insecureServiceValues ];
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
  # users.users.traefik.extraGroups = [ "docker" ];
}

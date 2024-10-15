{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.traefik-wrapper;
  active-domains = builtins.map (
    name: "{ main=\"${name}.${cfg.base-domain}\";sans=\"*.${name}.${cfg.base-domain}\";}"
  ) cfg.domain-subnets;

  apivalue = builtins.listToAttrs [
    {
      name = "api";
      value = {
        rule = "HostRegexp(`traefik\.([A-Za-z0-9]+)\.${cfg.base-domain}`)";
        service = "api@internal";
        entryPoints = [ "websecure" ];
        tls = {
          certResolver = "letsencrypt";
          domains = active-domains;
        };
      };
    }
  ];
  secureServiceValues = builtins.listToAttrs (
    builtins.map (nameVal: {
      name = "${nameVal}";
      value = {
        rule = "HostRegexp(`${nameVal}\.([A-Za-z0-9]+)\.${cfg.base-domain}`)";
        entryPoints = [ "websecure" ];
        service = "${nameVal}";
        tls = {
          certResolver = "letsencrypt";
          domains = active-domains;
        };
      };
    }) (builtins.attrNames cfg.service-definitions)
  );
  insecureServiceValues = builtins.listToAttrs (
    builtins.map (nameVal: {
      name = "${nameVal}-insecure";
      value = {
        rule = "HostRegexp(`${nameVal}\.([A-Za-z0-9]+)\.${cfg.base-domain}`)";
        entryPoints = [ "web" ];
        service = "${nameVal}";
        middlewares = "redirect-to-https";
      };
    }) (builtins.attrNames cfg.service-definitions)
  );

  serviceMapping = builtins.mapAttrs (name: value: {
    loadBalancer = {
      servers = [ { url = value.url; } ];
    };
  }) cfg.service-definitions;

in
with lib;
{
  options.services.traefik-wrapper = {
    enable = mkEnableOption "Traefik Config Wrapper";
    base-domain = mkOption {
      type = types.str;
      description = ''base domain in the format: XXXX.com'';
    };
    domain-subnets = mkOption {
      type = types.listOf types.str;
      description = ''
        List of subnets which will prefix the base domain.
      '';
    };
    service-definitions = mkOption {
      type = types.attrs;
      description = ''
        Configuration for Service names and url's for services. Provided name will be set as the prefix for the entire subnet.
        {
          name = "pihole";
          value = {
            url = "http://127.0.0.1:1398";
          };
        }
      '';
    };

  };
  config = mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

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
          services = serviceMapping;
          routers = lib.mkMerge [
            secureServiceValues
            insecureServiceValues
            apivalue
          ];
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
  };
}

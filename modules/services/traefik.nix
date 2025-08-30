{ config, lib, pkgs, pkgs-unstable, ... }:
let
  cfg = config.services.traefik-wrapper;
  active-domains = builtins.map (name:
    ''
      { main="${name}.${cfg.base-domain}";sans="*.${name}.${cfg.base-domain}";}'')
    cfg.domain-subnets;

  apivalue = builtins.listToAttrs [{
    name = "api";
    value = {
      rule = lib.strings.concatStringsSep " || "
        (builtins.map (subdomain: "Host(`${subdomain}.${cfg.base-domain}`)")
          cfg.domain-subnets);
      service = "api@internal";
      entryPoints = [ "websecure" ];
      tls = {
        certResolver = "letsencrypt";
        domains = active-domains;
      };
    };
  }];
  secureServiceValues = builtins.listToAttrs (builtins.map (nameVal: {
    name = "${nameVal}";
    value = {
      # rule = lib.strings.concatStringsSep " || " (builtins.map (subdomain:
      #   ''Host(`${nameVal}.${subdomain}.${cfg.base-domain}`)'')
      #   cfg.domain-subnets);
      rule = lib.strings.concatStringsSep " || " (builtins.map (subdomain:
        "Host(`${nameVal}.${subdomain}.${cfg.base-domain}`)")
        cfg.domain-subnets);
      # rule = "HostRegexp(`${nameVal}\.([A-Za-z0-9]+)\.${cfg.base-domain}`)";
      entryPoints = [ "websecure" ];
      service = "${nameVal}";
      tls = {
        certResolver = "letsencrypt";
      #   domains = builtins.map (name:
      #   ''
      #   { main="${name}.${cfg.base-domain}";sans="${nameVal}.${name}.${cfg.base-domain}";}'')
      # cfg.domain-subnets;
      domains = active-domains;
      };
    };
  }) (builtins.attrNames cfg.service-definitions));
  insecureServiceValues = builtins.listToAttrs (builtins.map (nameVal: {
    name = "${nameVal}-insecure";
    value = {
      # rule = lib.strings.concatStringsSep " || " (builtins.map (subdomain:
      #   "HostRegexp(`${nameVal}\.${subdomain}\.${cfg.base-domain}`)")
      #   cfg.domain-subnets);
      rule = lib.strings.concatStringsSep " || " (builtins.map (subdomain:
        ''Host(`${nameVal}.${subdomain}.${cfg.base-domain}`)'')
        cfg.domain-subnets);
      entryPoints = [ "web" ];
      service = "${nameVal}";
      middlewares = "redirect-to-https";
    };
  }) (builtins.attrNames cfg.service-definitions));

  serviceMapping = builtins.mapAttrs
    (name: value: { loadBalancer = { servers = [{ url = value.url; }]; }; })
    cfg.service-definitions;

in with lib; {
  options.services.traefik-wrapper = {
    enable = mkEnableOption "Traefik Config Wrapper";
    base-domain = mkOption {
      type = types.str;
      description = "base domain in the format: XXXX.com";
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

    sops.secrets.traefik = {
      sopsFile = ./traefikKey.env;
      format = "dotenv";
      restartUnits = [ "traefik.service" ];
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    systemd.services.traefik = {
      serviceConfig = {
        EnvironmentFile = "${config.sops.secrets.traefik.path}";
      };
    };

    services.traefik = {
      package = pkgs-unstable.traefik;
      enable = true;
      environmentFiles = [ "${config.sops.secrets.traefik.path}" ];

      dynamicConfigOptions = {
        http.middlewares = {
          redirect-to-https.redirectscheme = {
            scheme = "https";
            permanent = true;
          };
        };
        http = {
          services = serviceMapping;
          routers =
            lib.mkMerge [ secureServiceValues insecureServiceValues apivalue ];
        };
      };

      staticConfigOptions = {
        global = {
          checkNewVersion = true;
          sendAnonymousUsage = false;
        };
        api = {
          dashboard = true;
          debug = false;
        };
        log = {
          level = "DEBUG";
          filePath = "${config.services.traefik.dataDir}/traefik.log";
          format = "json";
        };
        entryPoints = {
          websecure = { address = ":443"; };
          web = { address = ":80"; };
        };

        certificatesResolvers = {
          letsencrypt.acme = {
            email = "garrettruffner42@gmail.com";
            storage = "${config.services.traefik.dataDir}/acme.json";
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

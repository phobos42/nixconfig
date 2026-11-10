{ config, lib, pkgs-unstable, ... }:
let
  cfg = config.services.traefik-wrapper;
  baseDomain = config.sops.placeholder.base_domain;
  hostName = lib.strings.toLower config.networking.hostName;
  tailscaleServiceValues = builtins.mapAttrs (_name: value: {
    rule = "Host(`${value.hostname}.${baseDomain}`)";
    entryPoints = [ "websecure" ];
    service = _name;
    middlewares = [ "tailscale-only" ];
    tls.certResolver = "letsencrypt";
  }) cfg.service-definitions;
  tailscaleRedirectValues = builtins.listToAttrs (builtins.map (name: {
    name = "${name}-redirect";
    value = {
      rule = "Host(`${cfg.service-definitions.${name}.hostname}.${baseDomain}`)";
      entryPoints = [ "web" ];
      service = name;
      middlewares = [ "tailscale-only" "redirect-to-https" ];
    };
  }) (builtins.attrNames cfg.service-definitions));
  publicServiceNames = builtins.filter
    (name: cfg.service-definitions.${name}.public)
    (builtins.attrNames cfg.service-definitions);
  publicServiceValues = builtins.listToAttrs (builtins.map (name: {
    name = "${name}-public";
    value = {
      rule = "Host(`${cfg.service-definitions.${name}.hostname}.${baseDomain}`)";
      entryPoints = [ "tunnel" ];
      service = name;
    };
  }) publicServiceNames);
  apiValue = {
    "api-${hostName}" = {
      rule = "Host(`traefik-${hostName}.${baseDomain}`)";
      service = "api@internal";
      entryPoints = [ "websecure" ];
      middlewares = [ "tailscale-only" ];
      tls.certResolver = "letsencrypt";
    };
  };

  serviceMapping = builtins.mapAttrs
    (name: value: { loadBalancer = { servers = [{ url = value.url; }]; }; })
    cfg.service-definitions;
  dynamicConfig = {
    http = {
      middlewares = {
        redirect-to-https.redirectscheme = {
          scheme = "https";
          permanent = true;
        };
        tailscale-only.ipAllowList.sourceRange = [ "100.64.0.0/10" ];
      };
      services = serviceMapping;
      routers = tailscaleServiceValues // tailscaleRedirectValues // publicServiceValues // apiValue;
    };
  };

in with lib; {
  options.services.traefik-wrapper = {
    enable = mkEnableOption "Traefik Config Wrapper";
    service-definitions = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          hostname = mkOption {
            type = types.str;
            default = name;
            description = "DNS label for this service on the configured base domain.";
          };
          url = mkOption {
            type = types.str;
            description = "Backend URL for the service.";
          };
          public = mkOption {
            type = types.bool;
            default = false;
            description = "Publish the service through the local Cloudflare Tunnel ingress.";
          };
        };
      }));
      description = ''
        Backend and exposure configuration keyed by service hostname.
        {
          name = "pihole";
          value = {
            url = "http://127.0.0.1:1398";
            public = true;
          };
        }
      '';
    };
      udp-ports = mkOption {
        type = types.listOf types.int;
        default = [ ];
        description = "List of UDP ports to open in the firewall.";
      };
      tcp-ports = mkOption {
        type = types.listOf types.int;
        default = [ 80 443 ];
        description = "List of TCP ports to open in the firewall.";
      };

  };

  config = mkIf cfg.enable {

    sops.secrets.base_domain = {
      sopsFile = ../../hosts/common.yaml;
      format = "yaml";
      key = "base_domain";
      restartUnits = [ "traefik.service" ];
    };
    sops.secrets.cloudflare-dns-api-token = {
      sopsFile = ../../hosts/common.yaml;
      format = "yaml";
      key = "CLOUDFLARE_DNS_API_TOKEN";
      restartUnits = [ "traefik.service" ];
    };
    sops.templates."base-domain.env".content = ''
      BASE_DOMAIN=${config.sops.placeholder.base_domain}
    '';
    sops.templates."traefik-cloudflare.env" = {
      content = ''
        CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-dns-api-token}
      '';
      owner = "traefik";
      group = "keys";
      mode = "0440";
    };
    sops.templates."traefik-dynamic.yaml" = {
      content = builtins.toJSON dynamicConfig;
      owner = "traefik";
      group = "keys";
      mode = "0440";
    };

    sops.secrets.traefik = {
      sopsFile = ./traefikKey.env;
      format = "dotenv";
      restartUnits = [ "traefik.service" ];
    };

    networking.firewall = {
      allowedTCPPorts = cfg.tcp-ports;
      allowedUDPPorts = cfg.udp-ports;
    };

    users.users.traefik.extraGroups = [ "keys" ];

    services.traefik = {
      package = pkgs-unstable.traefik;
      enable = true;
      environmentFiles = [
        "${config.sops.secrets.traefik.path}"
        config.sops.templates."traefik-cloudflare.env".path
      ];

      dynamicConfigFile = config.sops.templates."traefik-dynamic.yaml".path;

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
          tunnel = { address = "127.0.0.1:8080"; };
        };

        certificatesResolvers = {
          letsencrypt.acme = {
            email = "garrettruffner42@gmail.com";
            storage = "${config.services.traefik.dataDir}/acme.json";
            dnsChallenge = {
              provider = "cloudflare";
              delayBeforeCheck = 60;
              resolvers = [ "1.1.1.1:53" ];
            };
          };
        };
      };
    };
  };
}

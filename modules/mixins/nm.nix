{ config, lib, pkgs, ... }:
let 
  cfg = config.services.networkconfig;
  ini = pkgs.formats.ini { };
in with lib; {

  options.services.networkconfig = {
    enable = mkEnableOption "Network Manager Config Wrapper";
    hostname = mkOption {
      type = types.str;
      description = "Hostname for the machine.";
    };
    profiles = with lib.types;
      mkOption {
        type = attrsOf (submodule {
          freeformType = ini.type;
          options = {
            connection = {
              id = lib.mkOption {
                type = str;
                description =
                  "This is the name that will be displayed by NetworkManager and GUIs.";
              };
              type = lib.mkOption {
                type = str;
                description =
                  "The connection type defines the connection kind, like vpn, wireguard, gsm, wifi and more.";
                example = "vpn";
              };
            };
          };
        });
      };
    environmentFiles = mkOption {
      default = [ ];
      type = types.listOf types.path;
      example = [ "/run/secrets/network-manager.env" ];
      description = ''
        Files to load as environment file. Environment variables from this file
        will be substituted into the static configuration file using [envsubst](https://github.com/a8m/envsubst).
      '';
    };
    dns = mkOption {
      default = [ "1.1.1.1" "8.8.8.8" ];
      type = types.listOf types.str;
      example = [ "1.1.1.1" "8.8.8.8" ];
      description = "List of DNS servers to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ networkmanager ];
    networking = {
      firewall = { enable = false; };
      hostName = cfg.hostname;
      nameservers = cfg.dns;
      networkmanager = {
        enable = true;
        ensureProfiles = {
          environmentFiles = cfg.environmentFiles;
          profiles = cfg.profiles;
        };
      };
    };
  };
}


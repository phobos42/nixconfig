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
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ networkmanager ];
    networking = {
      firewall = { enable = false; };
      hostName = cfg.hostname;
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


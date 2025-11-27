{ pkgs, config, inputs, ... }:
let
  config-profiles = {
    ethernet = {
      connection = {
        id = "ethernet";
        permissions = "";
        interface-name = "enp0s31f6";
        type = "ethernet";
        autoconnect-priority = 100;
      };
      ipv4 = { method = "auto"; };
      ipv6 = { method = "auto"; };
    };
    home-wifi = {
      connection = {
        id = "home-wifi";
        permissions = "";
        interface-name = "wlp4s0";
        type = "wifi";
        autoconnect-priority = 50;
      };
      ipv4 = {
        dns-search = "";
        method = "auto";
      };
      ipv6 = {
        addr-gen-mode = "stable-privacy";
        dns-search = "";
        method = "auto";
      };
      wifi = {
        mac-address-blacklist = "";
        mode = "infrastructure";
        ssid = "$HOME_WIFI_SSID";
      };
      wifi-security = {
        auth-alg = "open";
        key-mgmt = "wpa-psk";
        psk = "$HOME_WIFI_PASSWORD";
      };
    };
    offsite1-wifi = {
      connection = {
        id = "offsite1-wifi";
        permissions = "";
        interface-name = "wlp4s0";
        type = "wifi";
        autoconnect-priority = 50;
      };
      ipv4 = {
        dns-search = "";
        method = "auto";
      };
      ipv6 = {
        addr-gen-mode = "stable-privacy";
        dns-search = "";
        method = "auto";
      };
      wifi = {
        mac-address-blacklist = "";
        mode = "infrastructure";
        ssid = "$OFFSITE1_WIFI_SSID";
      };
      wifi-security = {
        auth-alg = "open";
        key-mgmt = "wpa-psk";
        psk = "$OFFSITE1_WIFI_PASSWORD";
      };
    };
  };
in {
  sops.secrets = {
    networkconfig = {
      sopsFile = ./network.env;
      format = "dotenv";
      restartUnits = [ "NetworkManager.service" ];
    };
  };
  imports = with inputs.self.nixosModules; [ mixins-nm ];
  services = {
    networkconfig = {
      enable = true;
      hostname = "Perdido";
      environmentFiles = [ "${config.sops.secrets.networkconfig.path}" ];
      profiles = config-profiles;
    };
  };

  # environment.systemPackages = with pkgs; [ networkmanager ];
  # networking = {
  #   hostName = "Perdido";
  #   firewall = { enable = false; };
  #   networkmanager = {
  #     enable = true;
  #     ensureProfiles = {
  #       environmentFiles = [ "${config.sops.secrets.ethernetconfig.path}" ];
  #       profiles = {
  #         ethernet = {
  #           connection = {
  #             id = "ethernet";
  #             permissions = "";
  #             interface-name = "enp0s31f6";
  #             type = "ethernet";
  #             autoconnect-priority = 50;
  #           };
  #           ipv4 = { method = "auto"; };
  #           ipv6 = { method = "auto"; };
  #         };
  #         home-wifi = {
  #           connection = {
  #             id = "home-wifi";
  #             permissions = "";
  #             interface-name = "wlp4s0";
  #             type = "wifi";
  #             autoconnect-priority = 50;
  #           };
  #           ipv4 = {
  #             dns-search = "";
  #             method = "auto";
  #           };
  #           ipv6 = {
  #             addr-gen-mode = "stable-privacy";
  #             dns-search = "";
  #             method = "auto";
  #           };
  #           wifi = {
  #             mac-address-blacklist = "";
  #             mode = "infrastructure";
  #             ssid = "$HOME_WIFI_SSID";
  #           };
  #           wifi-security = {
  #             auth-alg = "open";
  #             key-mgmt = "wpa-psk";
  #             psk = "$HOME_WIFI_PASSWORD";
  #           };
  #         };
  #       };
  #     };
  #   };
  # };
}

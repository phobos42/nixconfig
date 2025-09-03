{ pkgs, config, inputs, ... }:
let
  config-profiles = {
    ethernet = {
      connection = {
        id = "ethernet";
        permissions = "";
        interface-name = "enp3s0";
        type = "ethernet";
        autoconnect-priority = 100;
      };
      ipv4 = { method = "auto"; };
      ipv6 = { method = "auto"; };
    };
  };
in {
  # sops.secrets = {
  #   networkconfig = {
  #     sopsFile = ./network.env;
  #     format = "dotenv";
  #     restartUnits = [ "NetworkManager.service" ];
  #   };
  # };
  imports = with inputs.self.nixosModules; [ mixins-nm ];
  services = {
    networkconfig = {
      enable = true;
      hostname = "Kraken";
      environmentFiles = [ ];
      profiles = config-profiles;
    };
  };
}

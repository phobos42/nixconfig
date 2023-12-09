{ lib, ... }:
{
  networking = {
    nameservers = [ "192.168.1.1" "192.168.1.100" "1.1.1.1" ];
    defaultGateway.address = "192.168.1.1";
    firewall = {
      enable = false;
    };
    networkmanager = {
      enable = true;
    };
  };
}

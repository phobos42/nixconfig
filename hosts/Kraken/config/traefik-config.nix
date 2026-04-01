{ config, inputs, ... }:
{
  imports = with inputs.self.nixosModules; [ services-traefik ];
  services = {
    traefik-wrapper = {
      enable = true;
      base-domain = "garrettruffner.com";
      domain-subnets = [
        "tailnethome"
      ];     
      tcp-ports = [ 80 443 8888 ];
      udp-ports = [ ];    
    };
  };
}

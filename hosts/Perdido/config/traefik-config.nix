{ config, inputs, ... }:
{
  imports = with inputs.self.nixosModules; [ services-traefik ];
  services = {
    traefik-wrapper = {
      enable = true;
      base-domain = "garrettruffner.com";
      domain-subnets = [
        "perdido"
      ];
      tcp-ports = [ 80 443 8888 137 138 139 389 445];
      udp-ports = [ 137 138 139 389 445 ];     
    };
  };
}
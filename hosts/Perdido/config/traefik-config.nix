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
      udp-ports = [ 80 443 8888 137 138 139 389 445 ];
      tcp-ports = [ 137 138 139 389 445 ];
    };
  };
}
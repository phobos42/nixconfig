{ config, inputs, ... }:
{
  imports = with inputs.self.nixosModules; [ services-traefik services-cloudflared ];
  services = {
    traefik-wrapper = {
      enable = true;
      tcp-ports = [ 80 443 8888 137 138 139 389 445];
      udp-ports = [ 137 138 139 389 445 ];     
    };
  };
  services.cloudflared-wrapper = {
    enable = true;
    tunnelId = "e6ab74b4-aa97-4c23-abd5-c371bddc422e";
    tokenSopsKey = "cloudflared_perdido_token";
  };
}
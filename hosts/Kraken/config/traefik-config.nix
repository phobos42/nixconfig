{ config, inputs, ... }:
{
  imports = with inputs.self.nixosModules; [ services-traefik services-cloudflared ];
  services = {
    traefik-wrapper = {
      enable = true;
      tcp-ports = [ 80 443 8888 ];
      udp-ports = [ ];    
    };
  };
  services.cloudflared-wrapper = {
    enable = true;
    tunnelId = "58eb98bf-6eab-42a6-8234-d9d5a42355be";
    tokenSopsKey = "cloudflared_kraken_token";
  };
}

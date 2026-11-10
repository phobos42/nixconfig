{ config, inputs, ... }:
{
  imports = with inputs.self.nixosModules; [ services-traefik services-cloudflared ];
  services = {
    traefik-wrapper = {
      enable = true;
    };
  };
  services.cloudflared-wrapper = {
    enable = false;
  };
}

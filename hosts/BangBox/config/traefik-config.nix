{ config, inputs, ... }:
{
  imports = with inputs.self.nixosModules; [ services-traefik ];
  services = {
    traefik-wrapper = {
      enable = true;
      base-domain = "garrettruffner.com";
      domain-subnets = [
        "home2"
        "tailnethome2"
      ];
      service-definitions = builtins.listToAttrs [
        {
          name = "homeassistant";
          value = {
            url = "http://192.168.1.102:8123";
          };
        }
      ];
    };
  };
}

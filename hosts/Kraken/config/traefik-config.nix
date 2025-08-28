{ config, inputs, ... }:
{
  imports = with inputs.self.nixosModules; [ services-traefik ];
  services = {
    traefik-wrapper = {
      enable = true;
      base-domain = "garrettruffner.com";
      domain-subnets = [
        "home"
        "home2"
        "tailnethome"
        "tailnethome2"
      ];
      # service-definitions = builtins.listToAttrs [
      #   {
      #     name = "craft";
      #     value = {
      #       url = "http://127.0.0.1:25565";
      #     };
      #   }        
      # ];
    };
  };
}

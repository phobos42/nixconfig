{ config, inputs, ... }:
{
  imports = with inputs.self.nixosModules; [ services-traefik ];
  services = {
    traefik-wrapper = {
      enable = true;
      base-domain = "garrettruffner.com";
      domain-subnets = [
        "home"
        "tailnethome"
      ];
      service-definitions = builtins.listToAttrs [
        {
          name = "sonarr";
          value = {
            url = "http://127.0.0.1:8989";
          };
        }
        {
          name = "jackett";
          value = {
            url = "http://127.0.0.1:9117";
          };
        }
        {
          name = "radarr";
          value = {
            url = "http://127.0.0.1:7878";
          };
        }
        {
          name = "deluge";
          value = {
            url = "http://127.0.0.1:8112";
          };
        }
        {
          name = "nextcloud";
          value = {
            url = "http://127.0.0.1:8081";
          };
        }
        {
          name = "jellyfin";
          value = {
            url = "http://127.0.0.1:8096";
          };
        }
        {
          name = "cockpit";
          value = {
            url = "http://127.0.0.1:9090";
          };
        }
        {
          name = "scrutiny";
          value = {
            url = "http://127.0.0.1:8085";
          };
        }
        {
          name = "homarr";
          value = {
            url = "http://127.0.0.1:7575";
          };
        }
        {
          name = "syncthing";
          value = {
            url = "http://127.0.0.1:8384";
          };
        }
        {
          name = "vaultwarden";
          value = {
            url = "http://127.0.0.1:8222";
          };
        }
        {
          name = "ollama";
          value = {
            url = "http://127.0.0.1:11434";
          };
        }
        {
          name = "openwebui";
          value = {
            url = "http://127.0.0.1:1398";
          };
        }
        {
          name = "craft";
          value = {
            url = "http://127.0.0.1:25565";
          };
        }
      ];
    };
  };
}

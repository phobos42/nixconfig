{ pkgs, config, ... }:
{
  virtualisation.oci-containers.containers = {
    flame = {
      image = "pawelmalak/flame:2.3.1";
      ports = [ "5005:5005" ];
      volumes = [
        "${config.users.users.box.home}/flame:/app/data"        
      ];
      environment.PASSWORD = "default";
    };
  };
}

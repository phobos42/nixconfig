{config, ...}:
{  
  virtualisation.oci-containers = {
    containers.homeassistant = {
      ports = [
        "8123:8123"
      ];
      volumes = [ "${config.users.users.box.home}/home-assistant:/config" ];
      environment.TZ = "America/Chicago";
      image = "ghcr.io/home-assistant/home-assistant:stable"; # Warning: if the tag does not change, the image will not be updated
      extraOptions = [ 
        "--network=host" 
        "--device=/dev/ttyACM0:/dev/ttyACM0"
        "--device=/dev/ttyACM1:/dev/ttyACM1"
      ];
    };
  };
}
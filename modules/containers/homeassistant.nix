{ config, ... }:
let
  portNumber = 8123;
in
{
  virtualisation.oci-containers = {
    containers.homeassistant = {
      ports = [ "${toString portNumber}:8123" ];
      volumes = [ "${config.users.users.box.home}/home-assistant:/config" ];
      environment.TZ = "America/Chicago";
      image = "ghcr.io/home-assistant/home-assistant:stable"; # Warning: if the tag does not change, the image will not be updated
      extraOptions = [
        "--network=host"
        "--device=/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20231102114932-if00:/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20231102114932-if00"
        "--device=/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00:/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00"
      ];
    };
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "vaultwarden";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}

{ config, ... }:
{
  services.zwave-js = {
    enable = true;
    port = 3000;
    secretsConfigFile = "${config.sops.secrets.zwavejs.path}";
    serialPort = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
  };
  sops.secrets = {
    zwavejs = {
      sopsFile = ./zwavejs.bin;
      format = "binary";
      restartUnits = [ "zwave-js" ];
      path = "/var/zwavejs.json";
      mode = "0444";
    };
  };
}

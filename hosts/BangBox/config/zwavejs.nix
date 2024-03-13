{
  services.zwave-js = {
    enable = true;
    port = 3000;
    secretsConfigFile = "/var/zwave-js-config";
    serialPort = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
  };
}

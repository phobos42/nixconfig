{
  services.zwave-js = {
    enable = true;
    port = 3000;
    secretsConfigFile = "/var/zwave-js-config";
    serialPort = "/dev/ttyACM0";
  };
}

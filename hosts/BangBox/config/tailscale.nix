{
  services.tailscale = {
    enable = true;
    authKeyFile = "/var/tailscale-key";
    extraUpFlags = [
      "--advertise-routes=192.168.1.0/24"
    ];
  };
}
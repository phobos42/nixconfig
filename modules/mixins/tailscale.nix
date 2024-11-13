{ config, ... }:{
  services.tailscale = {
    enable = true;
    authKeyFile = "${config.sops.secrets.tailscale.path}";
  };
  sops.secrets.tailscale = {
    sopsFile = ./tailscale.bin;
    format = "binary";
    restartUnits = [ "tailscaled.service" ];
  };
}

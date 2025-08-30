{ config, ... }:{
  services.tailscale = {
    enable = true;
    authKeyFile = "${config.sops.secrets.tailscale.path}";
    extraUpFlags = [ "--accept-routes" ];
    permitCertUid = "traefik";
  };
  sops.secrets.tailscale = {
    sopsFile = ./tailscale.bin;
    format = "binary";
    restartUnits = [ "tailscaled.service" ];
  };
}

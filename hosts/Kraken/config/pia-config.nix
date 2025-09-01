{ config, inputs, ... }:

let
  piaInterface = config.services.pia-vpn.interface;
in
{
  imports = with inputs.self.nixosModules; [ services-pia-vpn ];
  services = {
    pia-vpn = {
      enable = true;
      certificateFile = "${config.sops.secrets.piacert.path}";
      environmentFile = "${config.sops.secrets.piaenv.path}";
      portForward = {
        enable = true;
        # script = ''
        #   ${pkgs.transmission}/bin/transmission-remote --port $port || true
        # '';
      };
      maxLatency = 0.5;
    };
  };
  sops.secrets = {
    piaenv = {
      sopsFile = ./pia.env;
      format = "dotenv";
      restartUnits = [ "pia-vpn" ];
    };
    piacert = {
      sopsFile = ./piacert.bin;
      format = "binary";
      restartUnits = [ "pia-vpn" ];
    };
  };
}

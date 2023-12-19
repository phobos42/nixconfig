{ config, inputs, ... }:

let
  piaInterface = config.services.pia-vpn.interface;
in
{
  imports = with inputs.self.nixosModules;
    [
      services-pia-vpn
    ];
  services = {
    pia-vpn = {
      enable = true;
      certificateFile = "/var/pia-cert";
      environmentFile = "/var/pia-env";
      portForward = {
        enable = true;
        # script = ''
        #   ${pkgs.transmission}/bin/transmission-remote --port $port || true
        # '';
      };
    };
  };
}
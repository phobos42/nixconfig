{
  services.syncthing = {
    user = "syncthing";
    enable = true;
    dataDir = "/tank/shack/cloud/syncthing";
    configDir = "/tank/services/syncthing";
    settings = {
      gui = {
        insecureSkipHostcheck = true;
        enabled = true;
        tls = false;
        debugging = true;
        address = "0.0.0.0:8384";
      };
      folders = {
        Vortex = {
          versioning.type = "simple";
          path = "~/Vortex";
          label = "Vortex";
          id = "yzejp-g3vhs";
          enable = true;
          devices = [ "bigmac" "gphone" "pond" ];
        };
      };
      devices = {
        bigmac = {
          name = "bigmac";
          id = "4U3PFOX-TNPSVSJ-IX36QOC-CCOPF5L-XXKHXBM-4EDFFZS-67FCLLO-FRJVIAZ";
          autoAcceptFolders = true;
        };
        gphone = {
          name = "gphone";
          id = "L22YYBQ-FWMDNLL-RPWGWPQ-CREVHKB-ORL7HEE-F3N2ZL3-TMODDQQ-XLHJXQ5";
          autoAcceptFolders = true;
        };
        pond = {
          name = "pond";
          id = "MYINBMX-7N6EOK6-GKJTLZS-UUSAJJJ-OS2DXDM-PX7JPQZ-FH5W3XM-VU54RQE";
          autoAcceptFolders = true;
        };

      };
    };

  };
  users.users.syncthing.extraGroups = [ "users" ];
}

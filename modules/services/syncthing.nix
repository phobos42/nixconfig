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
          devices = [ "bigmac" ];
        };
      };
      devices = {
        bigmac = {
          name = "bigmac";
          id = "4U3PFOX-TNPSVSJ-IX36QOC-CCOPF5L-XXKHXBM-4EDFFZS-67FCLLO-FRJVIAZ";
          autoAcceptFolders = true;
        };
      };
    };

  };
  users.users.syncthing.extraGroups = [ "users" ];
}

{
  services.syncthing = {
    user = "syncthing";
    enable = true;
    dataDir = "/tank/shack/cloud/syncthing";
    configDir = "/tank/services/syncthing";
    settings = {
      gui = {
        insecureSkipHostcheck = true;
        enabled="true";
        tls="false";
        debugging="true";
        address="0.0.0.0:8384";
      };
    };

  };
  users.users.syncthing.extraGroups = [ "users" ];
}
{ pkgs, ... }:
let
  portNumber = 2283;
  python = pkgs.python313.override {
    self = python;
    packageOverrides = pythonFinal: pythonPrev: {
      imageio = pythonPrev.imageio.overridePythonAttrs (oldAttrs: {
        disabledTestPaths = (oldAttrs.disabledTestPaths or [ ]) ++ [
          "tests/test_pillow.py::test_png_16bit"
          "tests/test_pillow_legacy.py::test_png"
        ];
      });
    };
  };
  immichMachineLearning = pkgs.immich-machine-learning.override {
    python3 = python;
  };
  immichPackage = pkgs.immich.override {
    immich-machine-learning = immichMachineLearning;
  };
in
{
  services.immich = {
    package = immichPackage;
    user = "immich";
    group = "immich";
    enable = true;
    port = portNumber;
    settings  = null;
    mediaLocation = "/tank/shack/cloud/immich/";
    database = {
      enable = true;
      createDB = true;
    };
  };
  services.postgresql = {
    enable = true;
    # Ensure the database, user, and permissions always exist
    dataDir = "/tank/services/nextcloudpsdb";
    ensureDatabases = [ "immich" ];
    ensureUsers = [
      {
        name = "immich";
        ensureDBOwnership = true;
      }
    ];
  };
  systemd.services."immich" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "immich";
      value = {
        url = "http://localhost:${toString portNumber}";
        public = true;
      };
    }
  ];
}

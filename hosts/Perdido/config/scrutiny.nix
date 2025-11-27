{ ... }:
let
  portNumber = 8085;
in
{
  services.smartd.enable = true;
  virtualisation.oci-containers.containers = {
    scrutiny = {
      image = "ghcr.io/analogj/scrutiny:master-omnibus";
      ports = [
        "8085:8080"
        "8086:8086"
      ];
      volumes = [
        "/run/udev:/run/udev:ro"
        "./config:/opt/scrutiny/config"
        "./influxdb:/opt/scrutiny/influxdb"
      ];
      extraOptions = [
        "--cap-add=SYS_RAWIO"
        "--cap-add=SYS_ADMIN"
        # "--privileged"
        "--device=/dev/sda:/dev/sda"
        "--device=/dev/sdb:/dev/sdb"
        "--device=/dev/sdc:/dev/sdc"
        "--device=/dev/sdd:/dev/sdd"
      ];
    };
  };

  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "scrutiny";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}

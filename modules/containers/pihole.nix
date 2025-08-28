{ config, ... }:
let
  portNumber = 1398;
in
{
  # Stop systemd-resolved from listening to port 53
  services.resolved = {
    enable = true;
    extraConfig = "DNSStubListener=no";
  };
  virtualisation.oci-containers.containers = {
    pihole = {
      image = "pihole/pihole:latest";
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "${toString portNumber}:80"
      ];
      volumes = [
        "./etc-pihole:/etc/pihole"
        "./etc-dnsmasq.d:/etc/dnsmasq.d"
      ];
      environmentFiles = [ "${config.sops.secrets.pihole.path}" ];
    };
  };

  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "pihole";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
   sops.secrets.pihole = {
    sopsFile = ./pihole.env;
    format = "dotenv";
    restartUnits = [ "docker-pihole.service" ];
  };
}
# Original container definition:
#
# services:
#   pihole:
#     container_name: pihole
#     image: pihole/pihole:latest
#     # For DHCP it is recommended to remove these ports and instead add: network_mode: "host"
#     ports:
#       - "53:53/tcp"
#       - "53:53/udp"
#       - "67:67/udp" # Only required if you are using Pi-hole as your DHCP server
#       - "80:80/tcp"
#     environment:
#       TZ: 'America/Chicago'
#       # WEBPASSWORD: 'set a secure password here or it will be random'
#     # Volumes store your data between container upgrades
#     volumes:
#       - './etc-pihole:/etc/pihole'
#       - './etc-dnsmasq.d:/etc/dnsmasq.d'
#     #   https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
#     cap_add:
#       - NET_ADMIN # Required if you are using Pi-hole as your DHCP server, else not needed
#     restart: unless-stopped

{ config, pkgs, ... }:
{
  virtualisation = {
    oci-containers.backend = "podman";
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  # Add Members of the wheel group to the docker group.
  users.groups.docker.members = builtins.filter (x: builtins.elem "wheel" config.users.users."${x}".extraGroups) (builtins.attrNames config.users.users);
}

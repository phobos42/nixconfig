{ config, pkgs, ... }:
{
  virtualisation = {
    oci-containers.backend = "docker";
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
  # Add Members of the wheel group to the docker group.
  users.groups.docker.members = builtins.filter (x: builtins.elem "wheel" config.users.users."${x}".extraGroups) (builtins.attrNames config.users.users);
}

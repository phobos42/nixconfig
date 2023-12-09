{ config, inputs, ... }:
{
  nix.settings.trusted-users = [ "box" ];
  users.users.box = {
    isNormalUser = true;
    extraGroups = [
      "input"
      "lp"
      "wheel"
      "dialout"
    ];
  };
}

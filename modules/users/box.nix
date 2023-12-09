{ config, pkgs, inputs, ... }:
{
  nix.settings.trusted-users = [ "box" ];
  users.users.box = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    hashedPassword = "$6$x4R//6ix5xhSUKMI$Tu6jkZJOcRQo6UGVtcvZq.1N7SGibdZtkVfavKuaKYVNReeOGITTKlpYgQxGXc.KrQ8CWT5DKgydUKKz9hvGp.";
    packages = with pkgs; [
      tree
    ];
  };
}

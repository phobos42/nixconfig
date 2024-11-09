{
  config,
  pkgs,
  inputs,
  ...
}:
let
  keys = inputs.self.nixosModules.values-sshkeys;
in
{
  nix.settings.trusted-users = [ "box" ];
  users.users.box = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "media"
      "secure"
    ];
    hashedPassword = "$6$x4R//6ix5xhSUKMI$Tu6jkZJOcRQo6UGVtcvZq.1N7SGibdZtkVfavKuaKYVNReeOGITTKlpYgQxGXc.KrQ8CWT5DKgydUKKz9hvGp.";
    packages = with pkgs; [
      tree
      magic-wormhole
    ];
    openssh.authorizedKeys.keys = keys.box;
  };
}

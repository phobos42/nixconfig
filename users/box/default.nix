{ config, lib, pkgs, inputs, ... }:

{

  manual.manpages.enable = false;

  home = {
    username = "box";
    homeDirectory = "/home/box";
    packages = with pkgs; [
      file
      ripgrep
      fd
      magic-wormhole
      unzip
      btop
      htop
      pciutils
    ];
  };

  programs = {
    bash = {
      enable = true;
      bashrcExtra = '''';
      shellAliases = {
        #gr = "cd $(git rev-parse --show-toplevel)";
        n = "nix-shell -p";
        r = "nix repl ${inputs.utils.lib.repl}";
        # ssh = "env TERM=xterm-256color ssh";
        # ipv6off = "sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 -w net.ipv6.conf.default.disable_ipv6=1 -w net.ipv6.conf.lo.disable_ipv6=1";
        # ipv6on = "sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 -w net.ipv6.conf.default.disable_ipv6=0 -w net.ipv6.conf.lo.disable_ipv6=0";
      };
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.03";
}

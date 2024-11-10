{ 
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [ ./tmux.nix ./btop.nix ];
  tmux.enable = lib.mkDefault true;
  btop.enable = lib.mkDefault true;      
}

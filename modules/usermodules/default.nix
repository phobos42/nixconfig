{inputs, lib, config, ...}:
{
  imports = [ ./tmux.nix ];

  tmux.enable = lib.mkDefault true;
}
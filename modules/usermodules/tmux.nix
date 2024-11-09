{
  pkgs,
  lib,
  config,
  ...
}:
{
  options = {
    tmux.enable = lib.mkEnableOption "Add Tmux configuration";
  };
  config = lib.mkIf config.tmux.enable {
    environment.systemPackages = [ pkgs.tmuxPlugins.vim-tmux-navigator ];
    programs.tmux = {
      enable = true;
      clock24 = true;
      extraConfig = ''
        set -g default-terminal "tmux-256color"
        set -ag terminal-overrides ",xterm-256color:RGB"

        set -g prefix C-a
        unbind C-b
        bind-key C-a send-prefix

        unbind %
        bind \\ split-window -h

        unbind '"'
        bind - split-window -v

        unbind r
        bind r source-file ~/.tmux.conf

        bind j resize-pane -D 5
        bind k resize-pane -U 5
        bind l resize-pane -R 5
        bind h resize-pane -L 5

        bind -r m resize-pane -Z

        set -g mouse on

        set-window-option -g mode-keys vi

        bind-key -T copy-mode-vi 'v' send -X begin-selection # start selecting text with "v"
        bind-key -T copy-mode-vi 'y' send -X copy-selection # copy text with "y"

        unbind -T copy-mode-vi MouseDragEnd1Pane # don't exit copy mode when dragging with mouse

        # remove delay for exiting insert mode with ESC in Neovim
        set -sg escape-time 10

        # Navigation buttons support
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
        is_fzf="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?fzf$'"
        bind -n C-h run "($is_vim && tmux send-keys C-h) || tmux select-pane -L"
        bind -n C-j run "($is_vim && tmux send-keys C-j) || ($is_fzf && tmux send-keys C-j) || tmux select-pane -D"
        bind -n C-k run "($is_vim && tmux send-keys C-k) || ($is_fzf && tmux send-keys C-k)  || tmux select-pane -U"
        bind -n C-l run  "($is_vim && tmux send-keys C-l) || tmux select-pane -R"
        bind-key -n C-\\ if-shell "$is_vim" "send-keys C-\\" "select-pane -l"

        #Re-map clear screen
        bind-key -n C-u send-keys C-l
      '';
    };
  };
}

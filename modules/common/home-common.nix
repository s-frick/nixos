{ config, pkgs, ... }:

{
  imports = [
    ../nvim
  ];
  home.packages = with pkgs; [
    tmux
    fd
    ripgrep

    ranger
  ];

  programs.zsh = {
    enable = true;

    # optional: als Login-Shell setzen
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -la";
      gs = "git status";
      gp = "git pull";
      lg = "lazygit";
      vim = "nvim";
    };

    # optional: zusätzliche RC-Dateien / Einstellungen
    initContent = ''
      # hier kannst du alles reinschreiben, was sonst in .zshrc stehen würde
      # source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
      export EDITOR="nvim"
      bindkey -v
    '';
  };

  programs.tmux = {
    enable = true;
    # clock24 = true;
    # mouse = true;
    historyLimit = 100000;
    baseIndex = 1;
    keyMode = "vi";
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [ 
      nord
      yank
      vim-tmux-navigator
    ];

    extraConfig = ''
      set -ga terminal-overrides ",*:RGB"
      set -sg escape-time 0

      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel
      set -g focus-events on
      unbind C-b
      set-option -g prefix C-Space
      bind-key C-Space send-prefix
      # switch panes using Alt-arrow without prefix
      # bind -n C-h select-pane -L
      # bind -n C-l select-pane -R
      # bind -n C-k select-pane -U
      # bind -n C-j select-pane -D

      # resizing mit Alt/Meta + hjkl
      bind -n M-h resize-pane -L 10
      bind -n M-l resize-pane -R 10
      bind -n M-k resize-pane -U 10
      bind -n M-j resize-pane -D 10

      # don't rename windows automatically
      set-option -g allow-rename off
    '';
  };

  xdg.configFile."ranger/rc.conf".text = ''
    set preview_images true
    set preview_images_method kitty
  '';
}

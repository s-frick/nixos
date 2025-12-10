{ config, pkgs, ... }:
let
  input-overlay-presets = pkgs.fetchFromGitHub {
    owner = "univrsal";
    repo = "input-overlay";
    rev = "5.0.6";
    hash = "sha256-Y3GotIyljrDuEHcr1JTHMNgMPH2QmzWNvb+xTBmYVj8=";
  };
in
{
  imports = [
    ../nvim
  ];
  home.packages = with pkgs; [
    tmux
    fd
    ripgrep
    fzf
    bat
    eza
    tree

    rbw
    pinentry-all

    lazygit
    httpyac
    jq
    yq
    ranger
    showmethekey
  ];

  programs.obs-studio = {
    enable = true;

    plugins = with pkgs.obs-studio-plugins; [
      input-overlay
      wlrobs                # Wayland Screen Capture (wlroots)
      obs-pipewire-audio-capture
    ];
  };

  home.file.".local/bin/obs-x11" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      QT_QPA_PLATFORM=xcb exec obs "$@"
    '';
  };

  xdg.configFile."obs-input-overlay/presets".source = "${input-overlay-presets}/presets";

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
      bindkey -s ^f "tmux-sessionizer\n"
      bindkey -s ^p "rbw-fzf\n"
      bindkey -s ^e "ranger\n"

      MODE_PROMPT="%F{red}[N]%f"

      function zle-keymap-select {
        case $KEYMAP in
          vicmd) MODE_PROMPT="%F{green}[N]%f" ;;   # Normal mode
          viins|main) MODE_PROMPT="[I]" ;; # Insert mode
        esac
        zle reset-prompt
      }
      zle -N zle-keymap-select

      function zle-line-init {
        zle-keymap-select
      }
      zle -N zle-line-init
    '';

    oh-my-zsh = {
      enable = true;
      theme = "evan-vi";
      custom = "$HOME/.config/oh-my-zsh/custom/";

      plugins = [
        "git"
        "fzf"
        "sudo"
      ];
    };
  };

  xdg.configFile."oh-my-zsh/custom/evan-vi.zsh-theme".text = ''
    PROMPT='%m :: %1~ %B»%b '
    RPROMPT='$MODE_PROMPT'
  '';


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
      set -a terminal-features "tmux-256color:RGB"
      set -sg escape-time 0
      set -g focus-events on

      unbind C-b
      set-option -g prefix C-Space
      bind-key C-Space send-prefix

      set -g base-index 1
      set -g renumber-windows on
      set -g mode-keys vi
      set -g status-position top
      set -g status-justify absolute-centre
      set -g status-style "bg=colour233 fg=colour250"
      set -g window-status-format " [#I] #W "
      set -g window-status-current-style "fg=colour253 bg=colour238"
      set -g window-status-current-format " [#I] #W "
      set -g status-interval 5
      set -g status-left "#[fg=colour240] #S"
      set -g status-right "#[fg=colour240] %d.%m.%y"
      set -g message-style "bg=colour233 fg=colour250"
      set -g message-command-style "bg=colour233 fg=colour250"
      set -g clock-mode-colour colour250

      bind r source-file "~/git/configs/tmux/tmux.conf"
      bind b set -g status

      bind G neww -n "git" -S lazygit
      bind N neww -n "notes" -S "nvim ~/git/zettelkasten/log.md"
      bind C neww -n "configs" -S "nvim ~/git/configs/nixos/flake.nix"
      bind e neww -n "ranger" -S "ranger"
      bind E show-environment -g
      bind-key S run-shell "tmux-session-switcher"

      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel

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

  home.sessionPath = [ "$HOME/.local/scripts" "$HOME/.local/bin"  ];
  home.file.".local/scripts/tmux-sessionizer" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      if [[ $# -eq 1 ]]; then
          selected=$1
      else
          selected=$(
            find ~/git/work ~/git/private ~/git/old/probes \
                 ~/git/old/private ~/git/old/learning ~/git/monkey \
                 ~/git/foss ~/git/learning \
                 -mindepth 1 -maxdepth 1 -type d | 
            fzf --preview 'eza --tree --level=2 --color=always --git-ignore {}' \
                --preview-window=right:60%
            )
      fi

      if [[ -z $selected ]]; then
          exit 0
      fi

      selected_name=$(basename "$selected" | tr . _)
      tmux_running=$(pgrep tmux)

      if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
          tmux new-session -s $selected_name -c $selected
          exit 0
      fi

      if ! tmux has-session -t=$selected_name 2> /dev/null; then
          tmux new-session -ds $selected_name -c $selected
      fi

      if [[ -z $TMUX ]]; then
          tmux attach -t $selected_name
      else
          tmux switch-client -t $selected_name
      fi
    '';
  };
  home.file.".local/scripts/tmux-session-switcher" = {
    executable = true;
    text = ''
        session="$(
          tmux list-sessions -F "#{session_name}" 2>/dev/null |
            fzf \
              --prompt='tmux session > ' \
              --preview 'tmux list-windows -t {}' \
              --preview-window=right:60%:border-left
        )" || exit 1

        [ -z "$session" ] && exit 1

        tmux switch-client -t "$session"
    '';
  };
  home.file.".local/scripts/rbw-fzf" = {
    executable = true;
    text = ''
      set -eu
      IFS='

      '

      rbw unlocked >/dev/null 2>&1 || rbw unlock

      item=$(rbw list --fields name,user,id | fzf --height 60% --border --layout=reverse --preview 'rbw get {3} --raw | grep -v password' --preview-window=right,60%:wrap | awk '{print $3}')

      [ "$item" = "" ] && exit 1

      rbw get "$item" --clipboard
    '';
  };
}

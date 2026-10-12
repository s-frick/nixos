{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.agentflow;
  claudeDir = "${config.home.homeDirectory}/.claude";
  scriptsDir = "${config.home.homeDirectory}/.local/scripts";
  jq = lib.getExe pkgs.jq;

  mkScript' =
    name: runtimeInputs: prelude:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = prelude + builtins.readFile ./scripts/${name}.sh;
    };
  mkScript = name: runtimeInputs: mkScript' name runtimeInputs "";

  agentHelp = mkScript "agent-help" [ pkgs.tmux ];
  tmuxLayout = mkScript' "tmux-layout" (with pkgs; [ tmux git coreutils agentHelp ]) ''
    AGENTFLOW_DEFAULT_LAYOUT=''${AGENTFLOW_DEFAULT_LAYOUT:-${lib.escapeShellArg cfg.defaultLayout}}
  '';
  sessionizer =
    mkScript' "tmux-sessionizer" (with pkgs; [ tmux fzf eza findutils coreutils tmuxLayout ])
      ''
        AGENTFLOW_PATHS=''${AGENTFLOW_PATHS:-${lib.escapeShellArg (lib.concatStringsSep " " config.my.tmuxSessionizer.paths)}}
        AGENTFLOW_PATHS=''${AGENTFLOW_PATHS//\~/$HOME}
      '';
  scripts = [
    agentHelp
    tmuxLayout
    sessionizer
    (mkScript "tk" (with pkgs; [ tmux fzf git coreutils gnused sessionizer ]))
    (mkScript "agent-hook" (with pkgs; [ tmux jq ]))
    (mkScript "agent-next" (with pkgs; [ tmux gawk ]))
    (mkScript "agent-pick" (with pkgs; [ tmux fzf gawk coreutils ]))
    (mkScript "agent-status" (with pkgs; [ tmux gawk ]))
  ];

  # Claude Code hook event -> agent-hook argument
  hookEvents = {
    UserPromptSubmit = "prompt";
    PreToolUse = "tool";
    Notification = "notify";
    Stop = "stop";
    SessionEnd = "end";
  };
in
{
  options.my.agentflow.defaultLayout = lib.mkOption {
    type = lib.types.lines;
    default = ''
      agent nix run github:sadjow/claude-code-nix --
      edit nvim
      shell
    '';
    description = "tmux window layout for projects without a .tmux-layout file.";
  };

  config = {
    # Stable paths (~/.local/scripts) so Claude hooks survive rebuilds
    home.file = lib.listToAttrs (
      map (s: {
        name = ".local/scripts/${s.name}";
        value.source = lib.getExe s;
      }) scripts
    );

    programs.tmux.extraConfig = lib.mkAfter ''
      set -g window-status-format " [#I] #W#{?@agent_state, #{@agent_state},} "
      set -g window-status-current-format " [#I] #W#{?@agent_state, #{@agent_state},} "
      set -g status-right "#[fg=colour214]#(${scriptsDir}/agent-status)#[fg=colour240]%d.%m.%y"

      bind H run-shell -b "${scriptsDir}/agent-help --popup '#{client_name}'"
      bind f display-popup -E -w 80% -h 80% "${scriptsDir}/tmux-sessionizer"
      bind a run-shell "${scriptsDir}/agent-next"
      bind A display-popup -E -w 90% -h 80% "${scriptsDir}/agent-pick"
      bind W command-prompt -p "ticket:" "display-popup -E -w 80% -h 60% -d '#{pane_current_path}' \"${scriptsDir}/tk new '%1' || read -r -p 'Enter...'\""
      bind w display-popup -E -w 80% -h 80% -d "#{pane_current_path}" "${scriptsDir}/tk ls"
      bind D confirm-before -p "tk done #S? (y/n)" "display-popup -E -w 80% -h 40% -d '#{pane_current_path}' \"${scriptsDir}/tk done || read -r -p 'Enter...'\""
    '';

    home.activation.agentflowClaudeHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      ''
        settings="${claudeDir}/settings.json"
        mkdir -p "${claudeDir}"
        [ -f "$settings" ] || echo '{}' > "$settings"
      ''
      + lib.concatStrings (
        lib.mapAttrsToList (event: arg: ''
          if ! ${jq} -e '[.hooks.${event} // [] | .[].hooks[]?.command // ""] | any(contains("agent-hook"))' "$settings" > /dev/null 2>&1; then
            tmp=$(mktemp)
            ${jq} '.hooks.${event} //= [] | .hooks.${event} += [{"hooks": [{"type": "command", "command": "${scriptsDir}/agent-hook ${arg}", "timeout": 5}]}]' "$settings" > "$tmp" && mv "$tmp" "$settings"
          fi
        '') hookEvents
      )
    );
  };
}

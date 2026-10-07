{ pkgs, lib, config, ... }:
let
  ponytail-src = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "552acd5efd0aeae2583a12efe39373d2f076f25e";
    hash = "sha256-w6qwghKJYH3D6tQ3xUO7TtPXhYWiilId0BIEQSaUkNg=";
  };
  skills = [ "ponytail" "ponytail-audit" "ponytail-debt" "ponytail-gain" "ponytail-help" "ponytail-review" ];
  claudeDir = "${config.home.homeDirectory}/.claude";
  hooksDir = "${claudeDir}/ponytail/hooks";
  jq = lib.getExe pkgs.jq;
  addHook = import ../claude-hooks.nix { inherit pkgs lib; } hooksDir;
in
{
  # Hooks lesen ../skills/ponytail/SKILL.md relativ zu sich selbst, daher ganzes Repo verlinken
  home.file = {
    ".claude/ponytail".source = ponytail-src;
  } // lib.genAttrs (map (s: ".claude/skills/${s}") skills) (p: {
    source = "${ponytail-src}/skills/${baseNameOf p}";
  });

  home.activation.ponytail = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="${claudeDir}/settings.json"

    if [ ! -f "$settings" ]; then
      echo '{}' > "$settings"
    fi

    # Altlast: rtk-Hook entfernen (rtk-Modul wurde durch ponytail ersetzt).
    # Kann raus, sobald fuji, silverback und wsl einmal geswitcht haben.
    tmp=$(mktemp)
    ${jq} 'if .hooks.PreToolUse then .hooks.PreToolUse |= map(select([.hooks[]?.command // ""] | any(contains("rtk hook claude")) | not)) else . end' "$settings" > "$tmp" && mv "$tmp" "$settings"

    ${addHook "SessionStart" "ponytail-activate.js"}
    ${addHook "SubagentStart" "ponytail-subagent.js"}
    ${addHook "UserPromptSubmit" "ponytail-mode-tracker.js"}
  '';
}

{ pkgs, lib, config, ... }:
let
  caveman-src = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "25d22f864ad68cc447a4cb93aefde918aa4aec9f";
    hash = "sha256-FbmfhFaPs/SnSZdfNdErdIUHXt1FfBzErpPpLy8kdIc=";
  };
  hooksDir = "${caveman-src}/src/hooks";
  claudeDir = "${config.home.homeDirectory}/.claude";
  jq = lib.getExe pkgs.jq;
  node = lib.getExe pkgs.nodejs;
in
{
  home.file = {
    ".claude/hooks/caveman-activate.js".source = "${hooksDir}/caveman-activate.js";
    ".claude/hooks/caveman-mode-tracker.js".source = "${hooksDir}/caveman-mode-tracker.js";
    ".claude/hooks/caveman-config.js".source = "${hooksDir}/caveman-config.js";
    ".claude/hooks/caveman-stats.js".source = "${hooksDir}/caveman-stats.js";
    ".claude/hooks/caveman-statusline.sh" = {
      source = "${hooksDir}/caveman-statusline.sh";
      executable = true;
    };
  };

  home.activation.caveman = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="${claudeDir}/settings.json"
    flag="${claudeDir}/.caveman-active"

    if [ ! -f "$settings" ]; then
      echo '{}' > "$settings"
    fi

    if ! ${jq} -e '[.hooks.SessionStart // [] | .[].hooks[]?.command // ""] | any(contains("caveman-activate"))' "$settings" > /dev/null 2>&1; then
      tmp=$(mktemp)
      ${jq} '.hooks.SessionStart //= [] | .hooks.SessionStart += [{"hooks": [{"type": "command", "command": "${node} \"${claudeDir}/hooks/caveman-activate.js\"", "timeout": 5}]}]' "$settings" > "$tmp" && mv "$tmp" "$settings"
    fi

    if ! ${jq} -e '[.hooks.UserPromptSubmit // [] | .[].hooks[]?.command // ""] | any(contains("caveman-mode-tracker"))' "$settings" > /dev/null 2>&1; then
      tmp=$(mktemp)
      ${jq} '.hooks.UserPromptSubmit //= [] | .hooks.UserPromptSubmit += [{"hooks": [{"type": "command", "command": "${node} \"${claudeDir}/hooks/caveman-mode-tracker.js\"", "timeout": 5}]}]' "$settings" > "$tmp" && mv "$tmp" "$settings"
    fi

    if ! ${jq} -e 'has("statusLine")' "$settings" > /dev/null 2>&1; then
      tmp=$(mktemp)
      ${jq} '.statusLine = {"type": "command", "command": "bash \"${claudeDir}/hooks/caveman-statusline.sh\""}' "$settings" > "$tmp" && mv "$tmp" "$settings"
    fi

    if [ ! -f "$flag" ] && [ ! -L "$flag" ]; then
      echo -n 'full' > "$flag"
    fi
  '';
}

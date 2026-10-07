# addHook dir event script: activation snippet that appends a node hook to
# $settings (~/.claude/settings.json) unless one for that script exists.
{ pkgs, lib }:
let
  jq = lib.getExe pkgs.jq;
  node = lib.getExe pkgs.nodejs;
in
dir: event: script: ''
  if ! ${jq} -e '[.hooks.${event} // [] | .[].hooks[]?.command // ""] | any(contains("${script}"))' "$settings" > /dev/null 2>&1; then
    tmp=$(mktemp)
    ${jq} '.hooks.${event} //= [] | .hooks.${event} += [{"hooks": [{"type": "command", "command": "${node} \"${dir}/${script}\"", "timeout": 5}]}]' "$settings" > "$tmp" && mv "$tmp" "$settings"
  fi
''

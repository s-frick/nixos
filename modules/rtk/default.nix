{
  pkgs,
  lib,
  config,
  ...
}:
let
  rtk = pkgs.stdenv.mkDerivation {
    pname = "rtk";
    version = "0.42.4";
    src = pkgs.fetchurl {
      url = "https://github.com/rtk-ai/rtk/releases/download/v0.42.4/rtk-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-NJdRFtoR4J5QJQHa91gUPgsi7TpCoQ62f7aTpicNnjY=";

    };
    sourceRoot = ".";
    installPhase = ''
      install -Dm755 rtk $out/bin/rtk
    '';
  };
  claudeDir = "${config.home.homeDirectory}/.claude";
  jq = lib.getExe pkgs.jq;
in
{
  home.packages = [ rtk ];

  home.activation.rtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="${claudeDir}/settings.json"

    if [ ! -f "$settings" ]; then
      echo '{}' > "$settings"
    fi

    if ! ${jq} -e '[.hooks.PreToolUse // [] | .[].hooks[]?.command // ""] | any(contains("rtk hook claude"))' "$settings" > /dev/null 2>&1; then
      tmp=$(mktemp)
      ${jq} '.hooks.PreToolUse //= [] | .hooks.PreToolUse += [{"hooks": [{"type": "command", "command": "rtk hook claude"}]}]' "$settings" > "$tmp" && mv "$tmp" "$settings"
    fi
  '';
}

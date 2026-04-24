{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  forgejo-mcp = pkgs.buildGoModule {
    pname = "forgejo-mcp";
    version = "unstable";
    src = inputs.forgejo-mcp-src;

    # Nach dem ersten `nix build` schlägt dieser Hash fehl und zeigt den
    # korrekten Wert — diesen dann hier eintragen.
    vendorHash = "sha256-5CV4drUaYKtZ/RoydAatblhsqU8VWYzYByjhcb9KZVY=";

    meta = {
      description = "MCP server for Forgejo – connects AI assistants to Forgejo repositories";
      homepage = "https://codeberg.org/goern/forgejo-mcp";
      mainProgram = "forgejo-mcp";
    };
  };
in
{
  home.packages = [ forgejo-mcp ];

  # MCP-Konfiguration für Claude Code – projektweise in .claude/settings.json eintragen.
  # Beispiel (JSON):
  #
  # {
  #   "mcpServers": {
  #     "forgejo": {
  #       "type": "stdio",
  #       "command": "${forgejo-mcp}/bin/forgejo-mcp",  // oder einfach "forgejo-mcp" wenn im PATH
  #       "args": ["--transport", "stdio"],
  #       "env": {
  #         "FORGEJO_URL": "https://your-forgejo-instance.example.com",
  #         "FORGEJO_ACCESS_TOKEN": "<token>"
  #       }
  #     }
  #   }
  # }
}

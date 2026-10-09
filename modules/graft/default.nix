{
  pkgs,
  lib,
  config,
  ...
}:
let
  graft = pkgs.buildNpmPackage rec {
    pname = "graft";
    version = "0.21.1";
    src = pkgs.fetchFromGitHub {
      owner = "trailhq";
      repo = "Graft";
      rev = "v${version}";
      hash = "sha256-fop4YQ0uCGEmrqW6Wm35q0dlmBZMzMcVbMJkruIhnEY=";
    };
    npmDepsHash = "sha256-7iC2xhQcWnMYU+XicC44UFwsDYgKC5ZUWHK6c6/ecVc=";
    nodejs = pkgs.nodejs;
    # native tree-sitter grammars
    nativeBuildInputs = [ pkgs.python3 pkgs.makeWrapper ];
    env.DO_NOT_TRACK = "1";
    # plain `npm rebuild` runs tree-sitter-cli's install script, which downloads
    # a binary; rebuild only the native modules graft actually needs
    npmRebuildFlags = [ "--ignore-scripts" ];
    postConfigure = ''
      # some grammars pull tree-sitter-cli in; it is only a dev tool
      find node_modules -path '*/tree-sitter-cli/install.js' \
        -exec sh -c 'echo > "$1"' _ {} \;
      npm rebuild esbuild tree-sitter tree-sitter-go tree-sitter-java \
        tree-sitter-kotlin tree-sitter-php tree-sitter-python tree-sitter-r \
        tree-sitter-swift tree-sitter-typescript
    '';
    postInstall = ''
      wrapProgram $out/bin/graft --set-default DO_NOT_TRACK 1
    '';
    meta.mainProgram = "graft";
  };
in
{
  config = lib.mkIf config.my.graft.enable {
    home.packages = [ graft ];
  };
}

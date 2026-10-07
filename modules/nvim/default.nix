{
  pkgs,
  lib,
  config,
  ...
}:
let
  haskellToolchain = pkgs.haskell.packages.ghc96;

  vlime = pkgs.vimUtils.buildVimPlugin {
    pname = "vlime";
    version = "main";
    src = pkgs.fetchFromGitHub {
      owner = "vlime";
      repo = "vlime";
      rev = "e276e9a6f37d2699a3caa63be19314f5a19a1481"; # Tag von GitHub
      sha256 = "sha256-tCqN80lgj11ggzGmuGF077oqL5ByjUp6jVmRUTrIWJA=";
    };
    doCheck = false;
  };
  mermaid-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "mermaid.nvim";
    version = "main";
    src = pkgs.fetchFromGitHub {
      owner = "kevalin";
      repo = "mermaid.nvim";
      rev = "4da12693b3b4d63b67d07bafe8340b4abc265c70";
      sha256 = "sha256-SRg1V6fNlv+4Vrf1+mTNogIT/8X9DEl53+OhXm6crG8=";
    };
    doCheck = false;
  };
  tree-sitter-cli = pkgs.tree-sitter.overrideAttrs (old: rec {
    version = "0.26.1";
    src = pkgs.fetchFromGitHub {
      owner = "tree-sitter";
      repo = "tree-sitter";
      rev = "v${version}";
      hash = "sha256-k8X2qtxUne8C6znYAKeb4zoBf+vffmcJZQHUmBvsilA=";
    };
    cargoHash = "sha256-hnFHYQ8xPNFqic1UYygiLBWu3n82IkTJuQvgcXcMdv0=";
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-hnFHYQ8xPNFqic1UYygiLBWu3n82IkTJuQvgcXcMdv0=";
    };
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.llvmPackages.libclang ];
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.glibc.dev}/include";
    patches = [ ];
  });
in
{
  home.packages = lib.mkAfter (
    with pkgs;
    [
      tmux

      openjdk25
      jdt-language-server
      lombok
      # (writeShellScriptBin "jdtls-lombok" ''
      #   exec ${pkgs.jdt-language-server}/bin/jdtls \
      #     --jvm-arg=-javaagent:${pkgs.lombok}/share/java/lombok.jar "$@"
      # '')
      maven
      lua-language-server
      haskellToolchain.ghc
      haskellToolchain.haskell-language-server
      cabal-install
      nixd
      rust-analyzer
      clang-tools # clangd (fallback; project devshells bring their own)
      nixfmt
      ripgrep
      fd
      stylua
      shellcheck
      shfmt

      # Kotlin
      # kotlin-language-server  # replaced by optimized wrapper below
      (writeShellScriptBin "kotlin-language-server" ''
        exec ${pkgs.openjdk21}/bin/java \
          -Xmx2G \
          -Xms512M \
          -XX:+UseG1GC \
          -XX:MaxGCPauseMillis=200 \
          -XX:+UnlockExperimentalVMOptions \
          -XX:G1NewSizePercent=20 \
          -XX:G1MaxNewSizePercent=40 \
          -XX:+UseStringDeduplication \
          -XX:InitiatingHeapOccupancyPercent=45 \
          -Dfile.encoding=UTF-8 \
          -jar ${pkgs.kotlin-language-server}/share/kotlin-language-server/server/build/libs/server.jar "$@"
      '')
      gradle

      nodejs
      typescript
      typescript-language-server

      prettier
      prettierd
      eslint_d

      mermaid-cli

      vscode-extensions.vscjava.vscode-java-debug
      vscode-extensions.vscjava.vscode-java-test

      # commonlisp
      sbcl
      rlwrap
    ]
  );

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.openjdk21}/lib/openjdk";

    JAVA_DEBUG_SERVER_DIR = "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server";

    JAVA_TEST_SERVER_DIR = "${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test/server";

    LOMBOK_JAR = "${pkgs.lombok}/share/java/lombok.jar";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = false;
    vimAlias = true;

    # Falls du Node/Python-Provider für Plugins brauchst (Telescope, Treesitter, etc.)
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;

    extraPackages = with pkgs; [
      tree-sitter-cli
      (python3.withPackages (ps: [ ps.pynvim ]))
    ];

    plugins =
      (with pkgs.vimPlugins; [
        # LSP & Completion
        (pkgs.vimPlugins.nvim-jdtls.overrideAttrs (old: {
          src = pkgs.fetchFromGitHub {
            owner = "mfussenegger";
            repo = "nvim-jdtls";
            rev = "f73731b543f5971e0da9665eb1d7ceffe1fde71f"; # Beispiel-Commit
            sha256 = "sha256-9xmrwFXg70xTY+vxOvY2zxphwKzLZ6ncJ3wR544/VJ0="; # müsstest du einmal via nix-prefetch holen
          };
        }))
        #nvim-jdtls
        nvim-lspconfig

        nvim-dap
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        luasnip
        cmp_luasnip
        friendly-snippets
        todo-comments-nvim
        markview-nvim
        image-nvim

        nvim-dap-view
        nvim-dap-virtual-text


        # Syntax/Parsing
        (nvim-treesitter.withPlugins (p: [
          p.java
          p.haskell
          p.lua
          p.nix
          p.bash
          p.json
          p.yaml
          p.toml
          p.markdown
          p.markdown_inline
          p.html
          p.latex
          p.typst
          p.yaml

          p.commonlisp
          p.typescript
          p.tsx

          p.kotlin
          p.rust

          p.c
          p.cpp

          p.mermaid

        ]))

        # UI/Navigation
        telescope-nvim
        plenary-nvim
        lualine-nvim
        gitsigns-nvim
        which-key-nvim
        catppuccin-nvim
        gruber-darker-nvim
        mini-icons
        nvim-web-devicons
        vim-tmux-navigator

        # File tree
        neo-tree-nvim
        nui-nvim

      ])
      ++ [
        mermaid-nvim

        # commonlisp
        vlime
      ];
  };

  xdg.configFile."nvim".source = ./nvim;
}

{
  pkgs,
  lib,
  config,
  ...
}:
let
  # neotest-jdtls = pkgs.vimUtils.buildVimPlugin {
  #   pname = "neotest-jdtls";
  #   version = "dev";
  #   src = /home/sebi/git/configs/neotest-jdtls;
  #   doCheck = false;
  # };
  # neotest-jdtls = pkgs.vimUtils.buildVimPlugin {
  #   pname = "neotest-jdtls";
  #   version = "dev";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "s-frick";
  #     repo  = "neotest-jdtls";
  #     rev   = "c6659f2fadfef7b3547ea023d8c1464bfe5eb168";
  #     sha256 = "sha256-vKGFaLz4G9x1u0x5MlIVzCS0owdz4W+TMfkBOtWZMew=";
  #     # beim ersten Build wird Nix dir den richtigen Hash sagen;
  #     # den dann hier eintragen.
  #   };
  #   doCheck = false;
  # };

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
  neotest-jdtls = pkgs.vimUtils.buildVimPlugin {
    pname = "neotest-jdtls";
    version = "1.1.1";
    src = pkgs.fetchFromGitHub {
      owner = "atm1020";
      repo = "neotest-jdtls";
      rev = "v1.1.1"; # Tag von GitHub
      sha256 = "sha256-vKGFaLz4G9x1u0x5MlIVzCS0owdz4W+TMfkBOtWZMew=";
      # beim ersten Build wird Nix dir den richtigen Hash sagen;
      # den dann hier eintragen.
    };
    doCheck = false;
  };
in
{
  home.packages = lib.mkAfter (
    with pkgs;
    [
      tmux

      openjdk21
      jdt-language-server
      lombok
      # (writeShellScriptBin "jdtls-lombok" ''
      #   exec ${pkgs.jdt-language-server}/bin/jdtls \
      #     --jvm-arg=-javaagent:${pkgs.lombok}/share/java/lombok.jar "$@"
      # '')
      maven
      lua-language-server
      nixd
      nixfmt-rfc-style
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
      nodePackages_latest.typescript
      nodePackages_latest.typescript-language-server

      nodePackages_latest.prettier
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
        vim-wakatime

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
        diagram-nvim
        image-nvim

        nvim-dap-view
        nvim-dap-virtual-text

        # Neotest + Dependencies
        neotest
        nvim-nio
        FixCursorHold-nvim

        # Syntax/Parsing
        (nvim-treesitter.withPlugins (p: [
          p.java
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

        ]))

        # UI/Navigation
        telescope-nvim
        plenary-nvim
        lualine-nvim
        gitsigns-nvim
        which-key-nvim
        catppuccin-nvim
        mini-icons
        nvim-web-devicons
        vim-tmux-navigator

      ])
      ++ [
        neotest-jdtls

        # commonlisp
        vlime
      ];
  };

  xdg.configFile."nvim".source = ./nvim;
}

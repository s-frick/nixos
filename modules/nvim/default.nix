{ pkgs, lib, config, ... }:
let
    neotest-jdtls = pkgs.vimUtils.buildVimPlugin {
      pname = "neotest-jdtls";
      version = "dev";
      src = pkgs.fetchFromGitHub {
        owner = "s-frick";
        repo  = "neotest-jdtls";
        rev   = "c6659f2fadfef7b3547ea023d8c1464bfe5eb168";
        sha256 = "sha256-vKGFaLz4G9x1u0x5MlIVzCS0owdz4W+TMfkBOtWZMew=";
        # beim ersten Build wird Nix dir den richtigen Hash sagen;
        # den dann hier eintragen.
      };
      doCheck = false;
    };
in
{
    home.packages = lib.mkAfter (with pkgs; [
      tmux

      openjdk21
      jdt-language-server
      lombok
      (writeShellScriptBin "jdtls-lombok" ''
        exec ${pkgs.jdt-language-server}/bin/jdtls \
          --jvm-arg=-javaagent:${pkgs.lombok}/share/java/lombok.jar "$@"
      '')
      maven
      lua-language-server
      nixd
      nixfmt-rfc-style
      ripgrep
      fd
      stylua
      shellcheck
      shfmt

      nodejs
      nodePackages_latest.typescript
      nodePackages_latest.typescript-language-server

      nodePackages_latest.prettier
      prettierd
      eslint_d

      mermaid-cli
    ]);

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = false;
      vimAlias = true;
  
      # Falls du Node/Python-Provider für Plugins brauchst (Telescope, Treesitter, etc.)
      withNodeJs = true;
      withPython3 = true;
  

      plugins = (with pkgs.vimPlugins; [
        # LSP & Completion
        nvim-lspconfig
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        luasnip
        cmp_luasnip
        friendly-snippets
        nvim-FeMaco-lua
        mini-icons
        nvim-web-devicons
        vim-tmux-navigator
        todo-comments-nvim
        markview-nvim
        diagram-nvim
        image-nvim
  
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

          p.typescript 
          p.tsx

        ]))
  
        # UI/Navigation
        telescope-nvim
        plenary-nvim
        lualine-nvim
        gitsigns-nvim
        which-key-nvim
        catppuccin-nvim
      ])
      ++ [ neotest-jdtls ];
    };

    xdg.configFile."nvim".source = ./nvim;
}

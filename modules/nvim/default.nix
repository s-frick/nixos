{ pkgs, lib, config, ... }:
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
    ]);
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = false;
      vimAlias = true;
  
      # Falls du Node/Python-Provider für Plugins brauchst (Telescope, Treesitter, etc.)
      withNodeJs = true;
      withPython3 = true;
  
      # Tools und LSP-Server, die Neovim nutzen soll (landen im nvim-Wrapper-PATH)
  
      plugins = with pkgs.vimPlugins; [
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
      ];
    };

    xdg.configFile."nvim".source = ./nvim;
}

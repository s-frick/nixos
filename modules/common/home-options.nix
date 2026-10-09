{ lib, ... }:

{
  options.my = {
    rbw.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install rbw (Bitwarden CLI) plus the rbw-fzf picker and its ^p binding.";
    };

    nvim.copilot.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Add GitHub Copilot (copilot.vim) to neovim.";
    };

    graft.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install graft (codebase context graph CLI for coding agents).";
    };

    tmuxSessionizer.paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Directories tmux-sessionizer searches for projects (one level deep).";
    };
  };
}

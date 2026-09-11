{ lib, ... }:

{
  options.my = {
    rbw.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install rbw (Bitwarden CLI) plus the rbw-fzf picker and its ^p binding.";
    };

    tmuxSessionizer.paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "~/git/work"
        "~/git/private"
        "~/git/old/probes"
        "~/git/old/private"
        "~/git/old/learning"
        "~/git/monkey"
        "~/git/foss"
        "~/git/learning"
      ];
      description = "Directories tmux-sessionizer searches for projects (one level deep).";
    };
  };
}

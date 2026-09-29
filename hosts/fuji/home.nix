{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  ];

  programs.alacritty.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    config.global.hide_env_diff = true;
  };

  my.tmuxSessionizer.paths = [
    "~/git"
    "~/git/monkeysquad"
    "~/git/learning"
    "~/git/private"
  ];
}

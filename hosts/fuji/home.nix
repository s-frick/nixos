{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  ];

  programs.alacritty.enable = true;

  my.tmuxSessionizer.paths = [
    "~/git"
    "~/git/monkeysquad"
    "~/git/learning"
    "~/git/private"
  ];
}

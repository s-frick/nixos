{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # neovim
  ];

  my.tmuxSessionizer.paths = [
    "~/git"
    "~/git/arena"
    "~/git/tools"
  ];
}

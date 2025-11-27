{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
  ];

  programs.alacritty.enable = true;
}


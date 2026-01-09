{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  ];

  programs.alacritty.enable = true;
}


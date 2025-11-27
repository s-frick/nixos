{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    tmux
    fd
    ripgrep
  ];

  programs.zsh.enable = true;
}

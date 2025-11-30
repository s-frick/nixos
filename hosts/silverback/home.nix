{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # neovim
  ];


  xdg.configFile."kitty/kitty.conf".text = ''
    include ./dank-tabs.conf
    include ./dank-theme.conf

    cursor_trail 1
    cursor_trail_decay 0.1 0.4
  '';
}


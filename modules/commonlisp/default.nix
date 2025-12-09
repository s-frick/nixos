{ pkgs, lib, config, ... }:
{
    home.packages = lib.mkAfter (with pkgs; [
      emacs
    ]);

    xdg.configFile."emacs" = {
      recursive = true;
      source = pkgs.fetchgit {
        url = "https://github.com/doomemacs/doomemacs.git";
        rev = "9ef731939a130975227ac21370c09999f0dbccb3";
        sha256 = "sha256-oP8meVh4uf0WFporFSGjd0m+aK6BbhaY24wEi0mTySY=";
      };
    };

  # Wichtig: Doom-Localdir auf etwas Schreibbares legen
  home.sessionVariables = {
    DOOMDIR      = "${config.xdg.configHome}/doom";         # optional, falls du eigenes doom-dir nutzt
    DOOMLOCALDIR = "${config.xdg.dataHome}/doom";           # ~/.local/share/doom
  };

  home.sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];
}

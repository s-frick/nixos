# Standalone Home-Manager auf Ubuntu (WSL) mit Nix Package Manager.
# Kein NixOS: nur Home-Manager-Optionen, keine system-/services-Ebene.
{ pkgs, ... }:

{
  imports = [
    ../../modules/common/home-common.nix
  ];

  home.username = "sebi";
  home.homeDirectory = "/home/sebi";
  home.stateVersion = "25.05";

  # Non-NixOS-Integration: XDG_DATA_DIRS, .desktop-Dateien, LOCALE_ARCHIVE
  targets.genericLinux.enable = true;

  programs.home-manager.enable = true;

  # Kundenkontext: kein Bitwarden-Zugriff
  my.rbw.enable = false;

  my.tmuxSessionizer.paths = [
    "~/git"
  ];

  home.packages = with pkgs; [
    git
  ];
}

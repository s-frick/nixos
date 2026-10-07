{ pkgs, ... }:
{
  imports = [
    ../../modules/common
  ];

  wsl.enable = true;
  wsl.defaultUser = "sebi";
  users.users.sebi.isNormalUser = true;

  # wsl-spezifische Systempakete
  environment.systemPackages = with pkgs; [
    git-credential-oauth
  ];
  # vscode wsl nixos support
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    openssl
    curl
    zlib
    icu
  ];

  # wsl-spezifische Home-Manager-Erweiterungen für sebi
  home-manager.users.sebi.imports = [
    ./home.nix
  ];
}

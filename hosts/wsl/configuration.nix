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

  # wsl-spezifische Home-Manager-Erweiterungen für sebi
  home-manager.users.sebi.imports = [
    ./home.nix
  ];
}


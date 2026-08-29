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
    podman-compose
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
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;

  # wsl-spezifische Home-Manager-Erweiterungen für sebi
  home-manager.users.sebi.imports = [
    ./home.nix
  ];
}

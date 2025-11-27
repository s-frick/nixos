{ pkgs, ... }:
{
  desktop.mango.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  users.users.sebi.isNormalUser = true;


  # NixOS-spezifisch für fuji
  networking.hostName = "fuji";
  networking.networkmanager.enable = true;

  # fuji-spezifische Systempakete
  environment.systemPackages = with pkgs; [
    gimp3
  ];

  # fuji-spezifische Home-Manager-Erweiterungen für sebi
  home-manager.users.sebi.imports = [
    ./home.nix
  ];
}

{ pkgs, ... }:
{
  imports = [
    ../../modules/common
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  users.users.sebi.isNormalUser = true;


  # NixOS-spezifisch für silverback
  networking.hostName = "silverback";
  networking.networkmanager.enable = true;

  desktop.mango.enable = true;



  # fuji-spezifische Systempakete
  environment.systemPackages = with pkgs; [
    obs-studio
    gimp3
  ];

  # fuji-spezifische Home-Manager-Erweiterungen für sebi
  home-manager.users.sebi.imports = [
    ./home.nix
  ];
}

{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;
  desktop.mango.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # NixOS-spezifisch für fuji
  networking.hostName = "fuji";
  networking.networkmanager.enable = true;

  programs.steam.enable = true;
  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (pkgs.lib.getName pkg) [ "steam" "steam-unwrapped" ];

  # fuji-spezifische Systempakete
  environment.systemPackages = with pkgs; [
    gimp3
  ];

  # fuji-spezifische Home-Manager-Erweiterungen für sebi
  home-manager.users.sebi.imports = [
    ./home.nix
  ];
  services.udev.packages = [ pkgs.openocd ];
  users.groups.plugdev = { };
  users.users.sebi.extraGroups = [ "plugdev" ]; # Fallback, falls uaccess nicht greift (z.B.
}

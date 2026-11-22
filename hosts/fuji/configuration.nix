{ pkgs, ... }:
{
  imports = [
    ./sops.nix
    ../../modules/restic.nix
  ];
  services.restic.backups.storagebox.paths = [ "/home/sebi" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  desktop.mango.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # NixOS-spezifisch für fuji
  networking.hostName = "fuji";
  networking.networkmanager.enable = true;

  # Fernzugriff nur per Key, kein root-Login (openFirewall oeffnet Port 22)
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  users.users.sebi.openssh.authorizedKeys.keyFiles = [ ../../ssh/sebi.pub ];
  networking.wg-quick.interfaces.wg0 = {
    configFile = "/etc/wireguard/wg0.conf";
    autostart = false;
  };

  programs.steam.enable = true;
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "steam"
      "steam-unwrapped"
    ];

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

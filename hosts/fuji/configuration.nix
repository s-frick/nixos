{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;
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
    podman-compose
  ];

  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;

  # fuji-spezifische Home-Manager-Erweiterungen für sebi
  home-manager.users.sebi.imports = [
    ./home.nix
  ];
}

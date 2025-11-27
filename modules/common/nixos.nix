{ config, pkgs, lib, inputs, ... }:

{
  # Beispiel: Overlays aus deinen Inputs (falls sie welche exposen)
  # nixpkgs.overlays = [
  #   inputs.mangowc.overlays.default
  #   inputs.dankMaterialShell.overlays.default
  # ];

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # User global (gilt für alle Hosts)
  users.users.sebi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
}

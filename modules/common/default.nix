{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager

    ./nixos.nix
    ./home.nix
    ../windowManager/mango
  ];


  # Pullt nachts main von GitHub (flake-Attr setzt mkHost in flake.nix).
  # Lokale, ungepushte Änderungen werden dabei überschrieben.
  system.autoUpgrade = {
    enable = true;
    dates = "04:00";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };

  system.stateVersion = "25.05";
}

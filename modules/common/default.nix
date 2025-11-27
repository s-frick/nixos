{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager

    ./nixos.nix
    ./home.nix
    ../windowManager/mango
  ];


  system.stateVersion = "25.05";
}

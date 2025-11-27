{ config, pkgs, lib, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";

    users.sebi = {
      home.stateVersion = "25.05";
      imports = [
        ./home-common.nix
      ];
    };
  };
}

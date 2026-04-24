{ config, pkgs, lib, inputs, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; };

    users.sebi = {
      home.stateVersion = "25.05";
      imports = [
        ./home-common.nix
      ];
    };
  };
}

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
        ../forgejo-mcp
        ../claude-caveman
        ../rtk
      ];

      # NixOS-only extras (kein Bestandteil des portablen Kerns)
      home.packages = [ pkgs.showmethekey ];
    };
  };
}

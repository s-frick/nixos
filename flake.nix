{
  description = "Multi-host NixOS + Home-Manager (one user)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mangowc = {
      url = "github:DreamMaoMao/mangowc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.dgop.follows = "dgop";
    };

    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-wsl,
    home-manager,
    mangowc,
    dgop,
    dankMaterialShell,
    impermanence,
    ...
  }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations = {
        fuji = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          system = system;
          modules = [
            ./hosts/fuji/hardware.nix
            ./hosts/fuji/configuration.nix
            ./modules/common
          ];
        };

        silverback = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          system = system;
          modules = [
            ./hosts/silverback/hardware.nix
            ./hosts/silverback/configuration.nix
            ./modules/common
          ];
        };

        wsl = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          system = system;
          modules = [
            nixos-wsl.nixosModules.default
            ./hosts/wsl/configuration.nix
            ./modules/common
          ];
        };
      };
      # === Add custom build target ===
      packages.${system}.buildAll =
        let
          systems = builtins.attrValues self.nixosConfigurations;
          toplevels = map (cfg: cfg.config.system.build.toplevel) systems;
        in
          pkgs.runCommand "build-all" {
            buildInputs = toplevels;
          } ''
            mkdir -p $out
          '';
    };
}

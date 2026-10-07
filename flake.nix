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

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DMS greeter moved out of DankMaterialShell into its own repo
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    forgejo-mcp-src = {
      url = "git+https://codeberg.org/goern/forgejo-mcp";
      flake = false;
    };

    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, nixos-wsl, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkHost = name: extra: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = extra ++ [
          ./hosts/${name}/configuration.nix
          ./modules/common
        ];
      };
    in
    {
      nixosConfigurations = {
        fuji = mkHost "fuji" [ ./hosts/fuji/hardware.nix ];
        silverback = mkHost "silverback" [ ./hosts/silverback/hardware.nix ];
        wsl = mkHost "wsl" [ nixos-wsl.nixosModules.default ];
      };
      # Standalone Home-Manager (Nix Package Manager auf Ubuntu/WSL, kein NixOS)
      homeConfigurations."sebi@ubuntu" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./hosts/ubuntu/home.nix
        ];
      };

      # === Add custom build target ===
      packages.${system}.buildAll =
        let
          systems = builtins.attrValues self.nixosConfigurations;
          toplevels = map (cfg: cfg.config.system.build.toplevel) systems;
        in
        pkgs.runCommand "build-all"
          {
            buildInputs = toplevels;
          }
          ''
            mkdir -p $out
          '';
    };
}

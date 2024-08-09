{
  description = "Phobos NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixinate = {
      url = "github:phobos42/nixinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils = {
      url = "github:gytis-ivaskevicius/flake-utils-plus";
    };
  };

  outputs =
    {
      self,
      nixinate,
      home-manager,
      nixpkgs,
      nixos-hardware,
      utils,
      ...
    }@inputs:
    let 
    system = "aarch64-darwin";
    pkgs = import nixpkgs {
      inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      apps = nixinate.nixinate.x86_64-linux self;
      nixosModules = import ./modules { lib = nixpkgs.lib; };
      nixosConfigurations = {
        Kraken = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            utils.nixosModules.autoGenFromInputs
            ./hosts/Kraken/configuration.nix
            #home-manager.nixosModules.home-manager
          ];
          specialArgs = {
            inherit inputs;
          };
        };
        BangBox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            utils.nixosModules.autoGenFromInputs
            ./hosts/BangBox/configuration.nix
            #home-manager.nixosModules.home-manager
          ];
          specialArgs = {
            inherit inputs;
          };
        };
      };

      colmena =
        let
          configs = self.nixosConfigurations;
        in
        {
          meta = {
            nixpkgs = pkgs;
            specialArgs = {
              inherit inputs;
            };
            nodeNixpkgs = builtins.mapAttrs (name: value: value.pkgs) configs;
            nodeSpecialArgs = builtins.mapAttrs (name: value: value._module.specialArgs) configs;
          };

          # BangBox =
          #   { configs, ... }:
          #   {
          #     deployment = {
          #       targetHost = "192.168.1.102";
          #       targetUser = "box";
          #       tags = [ "server" ];
          #       allowLocalDeployment = false;
          #       buildOnTarget = true;
          #     };
          #     # imports = configs.BangBox.modules;
          #     imports = configs.BangBox._module.args.modules;
          #   };
        } // builtins.mapAttrs
        (name: value: {
          deployment = {
            targetHost = name;
            targetUser = "deploy";
            buildOnTarget = true;
            tags = [ "pc" ];
            allowLocalDeployment = false;
          };
          imports = value._module.args.modules;
        })
        configs;

      # // builtins.mapAttrs (machine: _: mkServer machine) (builtins.readDir ./config/machines/servers)
      # // builtins.mapAttrs
      #   (name: value: {
      #     deployment = {
      #       targetHost = name;
      #       tags = [ "pc" ];
      #       allowLocalDeployment = true;
      #     };
      #     imports = value._module.args.modules;
      #   })
      #   configs;
    };
}

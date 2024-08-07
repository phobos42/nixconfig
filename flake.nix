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
    { self
    , nixinate
    , home-manager
    , nixpkgs
    , nixos-hardware
    , utils
    , ...
    } @ inputs: {
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
          specialArgs = { inherit inputs; };
        };
        BangBox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            utils.nixosModules.autoGenFromInputs
            ./hosts/BangBox/configuration.nix
            #home-manager.nixosModules.home-manager
          ];
          specialArgs = { inherit inputs; };
        };     
      };
    };
}

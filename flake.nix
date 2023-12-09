{
  description = "Phobos NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs2311.url = "github:nixos/nixpkgs/nixos-23.11";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixinate = {
      url = "github:matthewcroughan/nixinate";
      inputs.nixpkgs.follows = "nixpkgs2311";
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
    , nixpkgs2311
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
      };
    };
}

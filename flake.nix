{
  description = "Phobos NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    # nixinate = {
    #   url = "github:phobos42/nixinate";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils = { url = "github:gytis-ivaskevicius/flake-utils-plus"; };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self,
    # nixinate,
    home-manager, nixpkgs, nixpkgs-unstable, nixos-hardware, utils, sops-nix
    , disko, ... }@inputs:
    let
      pkgs-unstable = import nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      targetHosts = {
        Kraken = {
          hostname = "kraken.kamori-hops.ts.net";
          systemArch = "x86_64-linux";
          deploymentUser = "deploy";
          tags = [ "server" ];
        };
        Perdido = {
          hostname = "perdido.kamori-hops.ts.net";
          systemArch = "x86_64-linux";
          deploymentUser = "deploy";
          tags = [ "server" ];
        };
      };
    in {
      nixosModules = import ./modules { lib = nixpkgs.lib; };
      nixosConfigurations = {
        Kraken = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            utils.nixosModules.autoGenFromInputs
            ./hosts/Kraken/configuration.nix
            sops-nix.nixosModules.sops
          ];
          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
          };
        };
        Perdido = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            utils.nixosModules.autoGenFromInputs
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/Perdido/configuration.nix
          ];
          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
          };
        };
        # BangBox = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   modules = [
        #     utils.nixosModules.autoGenFromInputs
        #     ./hosts/BangBox/configuration.nix
        #     sops-nix.nixosModules.sops
        #   ];
        #   specialArgs = {
        #     inherit inputs;
        #     inherit pkgs-unstable;
        #   };
        # };
      };

      colmena = let configs = self.nixosConfigurations;
      in {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };
          specialArgs = { inherit inputs; };
          nodeNixpkgs = builtins.mapAttrs (name: value: value.pkgs) configs;
          nodeSpecialArgs =
            builtins.mapAttrs (name: value: value._module.specialArgs) configs;
        };
      } // builtins.mapAttrs (name: value: {
        deployment = {
          targetHost = targetHosts.${name}.hostname or (throw
            "No target Host defined for ${name}");
          targetUser = targetHosts.${name}.deploymentUser or "deploy";
          buildOnTarget = true;
          tags = targetHosts.${name}.tags or [ ];
          allowLocalDeployment = false;
        };
        imports = value._module.args.modules;
      }) configs;
    };
}

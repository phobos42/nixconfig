{
  description = "Nix Package for flame";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];
      # Helper to provide system-specific attributes
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });

      version = "0.4.3";
    in
    {
      packages = forAllSystems ({ pkgs }: {
        default = pkgs.buildNpmPackage {
          pname = "hiccup";

          buildInputs = with pkgs; [
            nodejs_18
          ];          
          src = pkgs.fetchFromGitHub {
            owner = "ashwin-pc/hiccup";
            repo = "hiccup";
            rev = "refs/tags/v${version}";
            hash = "sha256-";
           
          };         

          configurePhase = ''
            npm install
          '';

          buildPhase = ''            
            npm run build
          '';

          installPhase = ''            
            cp -r app/build/* $out/
          '';

          npmDepsHash = "sha256-";
        };        
      });
    };
}

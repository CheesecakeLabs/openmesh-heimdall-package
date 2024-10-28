{
  description = "Polygon Heimdall Validator Node";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-compat.url = "github:nix-community/flake-compat";
  };

  outputs = { self, nixpkgs, ... }:
    let
      # Supported architectures: x86_64 and aarch64
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Import Nixpkgs for all systems
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      # Define the Heimdall package for all systems
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in {
          heimdall-polygon = import ./pkgs/heimdall/default.nix {
            lib = pkgs.lib;
            stdenv = pkgs.stdenv;
            buildGoModule = pkgs.buildGoModule;
            fetchFromGitHub = pkgs.fetchFromGitHub;
            libobjc = pkgs.darwin.libobjc;
            IOKit = pkgs.darwin.IOKit;
          };
        }
      );

      # Make Heimdall the default package
      defaultPackage = forAllSystems (system: self.packages.${system}.heimdall-polygon);

      # Define devShell for development
      devShell = forAllSystems (system: 
        nixpkgsFor.${system}.mkShell {
          nativeBuildInputs = [
            self.packages.${system}.heimdall-polygon
            nixpkgsFor.${system}.go
            nixpkgsFor.${system}.git
          ];
        }
      );

      # NixOS module output for Heimdall
      nixosModules.default = import ./modules/heimdall/default.nix;
    };
}
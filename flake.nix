{
  description = "Polygon Heimdall Validator Node";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      ...
    }:
    let
      # A helper that defines the attributes for all relevant systems
      eachSystem =
        f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {
      packages = eachSystem (
        { pkgs, ... }:
        {
          default = pkgs.callPackage ./nix/package.nix {
            lib = pkgs.lib;
            stdenv = pkgs.stdenv;
            buildGoModule = pkgs.buildGoModule;
            fetchFromGitHub = pkgs.fetchFromGitHub;
            libobjc = pkgs.darwin.libobjc;
            IOKit = pkgs.darwin.IOKit;
          };
        }
      );

      checks = eachSystem (
        { pkgs, system, ... }:
        {
          package = self.packages.${system}.default;
          nixos-module = pkgs.callPackage ./nix/nixos-test.nix { };
        }
      );

      # NixOS module output for Heimdall
      nixosModules.default = import ./nix/nixos-module.nix;
    };
}
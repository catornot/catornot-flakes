{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    erosanix.url = "github:emmanuelrosa/erosanix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      erosanix,
    }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./pkgs
      ];

      flake.modules.nixos = {
        northstart-dedicated = import ./modules/northstart-dedicated.nix { self = self; };
      };

      flake.overlays.northstar = final: prev: {
        package-wine-env = self.packages.wine-env;
        package-nswrap = self.packages.nswrap;
        package-nswine-run = self.packages.nswine-run;
      };

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}

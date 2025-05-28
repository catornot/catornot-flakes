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
        (
          { withSystem, ... }:
          {
            flake.overlays.northstar =
              final: prev:
              withSystem prev.stdenv.hostPlatform.system (
                # perSystem parameters. Note that perSystem does not use `final` or `prev`.
                { config, ... }:
                {
                  nswine-env = config.packages.nswine-env;
                  nswrap = config.packages.nswrap;
                  nswine-run = config.packages.nswine-run;
                }
              );
          }
        )
      ];

      flake.nixosModules = {
        northstar-dedicated = import ./modules/northstart-dedicated.nix { self = self; };
      };

      perSystem =
        { pkgs, config, ... }:
        {
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}

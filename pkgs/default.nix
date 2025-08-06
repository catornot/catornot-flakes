{
  inputs,
  ...
}:
{
  systems = [ "x86_64-linux" ];

  perSystem =
    {
      system,
      pkgs,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      packages =
        let
        in
        rec {
          papa-src = pkgs.callPackage ./papa-src { };
          papa = pkgs.callPackage ./papa { };
          titanfall2 = pkgs.callPackage ./titanfall2 { };
          northstar = pkgs.callPackage ./northstar { };
          nswrap = pkgs.callPackage ./nswrap { };
          nswine-run = pkgs.callPackage ./nswine-run {
            nswrap = nswrap;
            nswine-env-path = pkgs.lib.fakeHash;
          };
          nswine-env = pkgs.callPackage ./nswine-env { };
          northstar-dedicated = pkgs.callPackage ./northstar-dedicated {
            titanfall2 = titanfall2;
            northstar = northstar;
          };
        };
    };
}

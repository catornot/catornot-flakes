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
        config.allowUnsupportedSystem = true;
      };

      packages =
        let
          pkgs-win = import inputs.nixpkgs {
            inherit system;
            crossSystem = {
              config = "x86_64-w64-mingw32";
              libc = "msvcrt";
            };
            config.microsoftVisualStudioLicenseAccepted = true;
            config.allowUnfree = true;
            config.allowUnsupportedSystem = true;
          };
        in
        rec {
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
          sere = pkgs.callPackage ./sere { inherit pkgs-win; };
          tf2vpk = pkgs.callPackage ./tf2vpk { };
        };
    };
}

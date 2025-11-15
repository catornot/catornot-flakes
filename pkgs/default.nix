{
  inputs,
  self,
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
          r2overlay = pkgs.callPackage ./r2overlay { };
          northstar = pkgs.callPackage ./northstar { };
          nswrap = pkgs.callPackage ./nswrap { };
          nswrap-unpatched = pkgs.callPackage ./nswrap { doNotPatch = true; };
          nswine-run = pkgs.callPackage ./nswine-run {
            nswrap = nswrap;
            nswine-env-path = nswine-env;
          };
          nswine-run-local = pkgs.callPackage ./nswine-run {
            nswrap = nswrap;
            nswine-env-path = nswine;
            isLocal = true;
          };
          nswine-env = pkgs.callPackage ./nswine-env { inherit nswine; };
          nswine = pkgs.callPackage ./nswine { };
          check-hash = pkgs.callPackage ./check-hash { };
          northstar-dedicated = pkgs.callPackage ./northstar-dedicated {
            titanfall2 = titanfall2;
            r2overlay = r2overlay;
            northstar = northstar;
            inherit (self.libExport pkgs) makeR2Northstar;
          };
          northstar-dedicated-test = pkgs.callPackage ./northstar-dedicated {
            titanfall2 = titanfall2;
            r2overlay = r2overlay;
            northstar = northstar;
            northstar-packages = (
              builtins.map (self.libExport pkgs).nameToPackage [
                {
                  name = "cat_or_not-AmpedMobilepoints-0.0.4";
                  sha256 = "sha256-xDhpK9DmQaPWhahyyPfPx7izUo5ghuLBaWsaVDP0oX4=";
                }
              ]
            );
            inherit (self.libExport pkgs) makeR2Northstar;
          };
          sere = pkgs.callPackage ./sere { inherit pkgs-win; };
          tf2vpk = pkgs.callPackage ./tf2vpk { };
          flightcore = pkgs.callPackage ./flightcore { };
        };
    };
}

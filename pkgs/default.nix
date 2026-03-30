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
        config.microsoftVisualStudioLicenseAccepted = true;
        overlays = [ (import inputs.rust-overlay) ];
      };

      packages =
        let
          erosanixLib = inputs.erosanix.lib."${system}";
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
          playlistrotations = pkgs.callPackage ./playlistrotations { rotationsDef = ""; };
          tf2vpk = pkgs.callPackage ./tf2vpk { };
          flightcore = pkgs.callPackage ./flightcore { };
          rustcon = pkgs.callPackage ./rustcon { };
          satisfactory-3d-map = pkgs.callPackage ./satisfactory-3d-map { };
          northstar-dedicated-docker = pkgs.callPackage ./northstar-dedicated-docker {
            inherit
              nswrap
              nswine
              self
              northstar
              titanfall2
              ;
          };
          minecraft-lce-wine = pkgs.callPackage ./minecraft-lce-wine {
            inherit (erosanixLib) mkWindowsAppNoCC copyDesktopIcons makeDesktopIcon;
            inherit check-hash;
          };
          minecraft-consoles = pkgs.callPackage ./minecraft-consoles { };
          maxima = pkgs.callPackage ./maxima { };
          maxima-windows = pkgs.callPackage ./maxima-windows { inherit maxima; };
          titanfall2-wine = pkgs.callPackage ./titanfall-wine {
            inherit (erosanixLib) mkWindowsAppNoCC copyDesktopIcons makeDesktopIcon;
            inherit maxima-windows;
          };
          mrvn-radiant = pkgs.callPackage ./mrvn-radiant { };
          sqformat = pkgs.callPackage ./sqformat { };
        };
    };
}

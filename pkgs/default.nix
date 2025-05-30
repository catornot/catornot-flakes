{
  inputs,
  self,
  ...
}:
{
  systems = [ "x86_64-linux" ];

  perSystem =
    {
      config,
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
          erosanix-pkgs = (pkgs // inputs.erosanix.packages.x86_64-linux // inputs.erosanix.lib.x86_64-linux);
        in
        rec {
          papa-src = pkgs.callPackage ./papa-src { };
          papa = pkgs.callPackage ./papa { };
          titanfall2 = pkgs.callPackage ./titanfall2 { };
          nswrap = pkgs.callPackage ./nswrap { };
          nswine-run = pkgs.callPackage ./nswine-run {
            nswrap = nswrap;
            nswine-env-path = pkgs.lib.fakeHash;
          };
          nswine-env = pkgs.callPackage ./nswine-env { };
          northstar-dedicated = pkgs.callPackage ./northstar-dedicated {
            mkWindowsApp = erosanix-pkgs.mkWindowsApp;
            wine = erosanix-pkgs.wineWowPackages.base;
          };
        };
    };
}

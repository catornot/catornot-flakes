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
        in
        {
          papa-src = pkgs.callPackage ./papa-src { };
          papa = pkgs.callPackage ./papa { };
        };
    };
}

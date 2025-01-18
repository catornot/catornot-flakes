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
          papa = pkgs.callPackage ./papa { };
        };
    };
}

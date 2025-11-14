{
  stdenvNoCC,
  lib,
  fetchurl,
  unzip,
}:
let
in
stdenvNoCC.mkDerivation rec {
  pname = "Northstar";
  version = "1.31.3";

  src = fetchurl {
    url = "https://github.com/R2Northstar/Northstar/releases/download/v${version}/${pname}.release.v${version}.zip";
    sha256 = "sha256-kz76mmyZGYisFwxL7KllRlXMfSk+wRlZH0CfRgZRuPg=";
  };

  dontUnpack = true;

  installPhase = ''
    ${unzip}/bin/unzip $src -d $out
  '';

  meta = {
    description = "Northstar Client";
    homepage = "https://northstar.tf/";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}

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
  version = "1.30.2";

  src = fetchurl {
    url = "https://github.com/R2Northstar/Northstar/releases/download/v${version}/${pname}.release.v${version}.zip";
    sha256 = "sha256-u6nuy97ia4jMd7CW9RtvhhLAe/mvTYk9J76Ha8a44yI=";
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

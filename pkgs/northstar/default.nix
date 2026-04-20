{
  stdenvNoCC,
  lib,
  fetchzip,
  version ? "1.31.8",
  sha256 ? "sha256-s+1ZElX7dEOnd31kx+Hw+JPeDT8JjYY1SwRY/iPu5b8=",
  nix-update-script,
}:
let
in
stdenvNoCC.mkDerivation rec {
  pname = "Northstar";
  inherit version;

  src = fetchzip {
    url = "https://github.com/R2Northstar/Northstar/releases/download/v${version}/${pname}.release.v${version}.zip";
    stripRoot = false;
    inherit sha256;
  };

  installPhase = ''
    mkdir $out
    cp -r $src/* $out
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Northstar Client";
    homepage = "https://northstar.tf/";
    license = lib.licenses.mit;
    platforms = builtins.concatLists (builtins.attrValues lib.platforms);
    maintainers = [ ];
  };
}

{
  stdenvNoCC,
  lib,
  fetchzip,
  version ? "1.31.9",
  sha256 ? "sha256-kjKu5hkB+hRsp4bZT0C/pM4diBBKFp98L9Lz70eqlog=",
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

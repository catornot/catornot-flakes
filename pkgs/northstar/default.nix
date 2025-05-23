{
  pkg-config,
  openssl,
  stdenv,
  lib,
  autoPatchelfHook,
  fetchurl,

}:
let
in
stdenv.mkDerivation rec {
  pname = "Northstar";
  version = "1.30.0";

  src = fetchurl {
    url = "https://github.com/R2Northstar/Northstar/releases/download/v${version}/${pname}.release.v${version}.zip";
    sha256 = "sha256-NmKWql+hhpwk4Sio/7UH8XCc+feJQ9LVRCKgQv4b3ww=";
  };

  nativeBuildInputs = [
  ];
  buildInputs = [
  ];

  sourceRoot = ".";

  phases = [ "installPhase" ];
  installPhase = ''
  '';

  meta = {
  };
}

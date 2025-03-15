{
  stdenv,
  lib,
  pkgs,
}:
stdenv.mkDerivation rec {
  name = "Northstar";
  version = "1.30.0";

  src = pkgs.fetchurl {
    url = "https://github.com/R2Northstar/Northstar/releases/download/v${version}/${name}.release.v${version}.zip";
    sha256 = "sha256-NmKWql+hhpwk4Sio/7UH8XCc+feJQ9LVRCKgQv4b3ww=";
  };

  nativeBuildInputs = with pkgs; [
    unzip
  ];
  buildInputs = [
  ];

  unpackPhase = ''
    unzip $src -d $out
  '';

  installPhase = ''
  '';

  env = {
    LIBGL_ALWAYS_SOFTWARE = 1;
    GALLIUM_DRIVER = "llvmpipe";
  };

  meta = {
    description = "";
    homepage = "";
    license = lib.licenses.unfree;
    mainProgram = "";
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}

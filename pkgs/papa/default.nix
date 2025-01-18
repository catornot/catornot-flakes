{
  pkg-config,
  openssl,
  stdenv,
  lib,
}:
let
in
stdenv.mkDerivation rec {
  pname = "papa";
  version = "4.0.0";
  
  src = builtins.fetchurl {
   url = "https://github.com/AnActualEmerald/papa/releases/download/v4.0.0/papa";
   sha256 = "sha256:12gqm4mfvac0cybkdhx9c7617anx377himham06asd4xv8i99ci5";
  };

  buildInputs = [
    pkg-config
    openssl
  ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    install -m755 -D papa $out/bin/papa
    runHook postInstall
  '';

  meta = {
    description = "A cli mod manager for the Northstar launcher";
    homepage = "https://github.com/AnActualEmerald/papa";
    license = lib.licenses.mit;
    mainProgram = "papa";
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}


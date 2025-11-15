{
  lib,
  rustPlatform,
  fetchFromGitHub,
  stdenv,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rustcon";
  version = "3.2.0";

  src = fetchFromGitHub {
    owner = "cblanken";
    repo = finalAttrs.pname;
    rev = "df4a5fe22b9143f1257b4bfb4f11d48c480a3d0d";
    hash = "sha256-9JO1iiXFIXCfIqR1ly1vULJP6UEtyXMNQ8jMo6joi6Q=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [
    stdenv.shellPackage
  ];

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';

  shellPath = "bin/${finalAttrs.pname}";

  meta = {

    description = "Installer/Updater/Launcher for Northstar";
    homepage = "https://github.com/cblanken/rustcon.git";
    license = with lib.licenses; [
      mit
    ];
    mainProgram = "rustcon";
  };
})

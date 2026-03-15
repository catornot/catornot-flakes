{
  lib,
  rustPlatform,
  fetchFromGitHub,
  protobuf,
  protobuf_25,
  pkgsBuildHost,
  libxkbcommon,
  vulkan-loader,
  libx11,
  libxcursor,
  libxrandr,
  xinput,
  wayland,
  pkg-config,
  expat,
  fontconfig,
  freetype,
  libGL,
  autoPatchelfHook,
  makeWrapper,
}:
let
  toolchain = pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "Maxima";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "ArmchairDevelopers";
    repo = finalAttrs.pname;
    rev = "cbde5f0002d6f16fb67dfa79ad96b705e1c591bf";
    hash = "sha256-6SAbVDm1S/QJsgCQYjEB9ydsrElofZfhu+aMug4rCnQ=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "async-compression-0.4.5" = "sha256-6PRxfc//AsTJ8MMN3bql3kaNs+jLS7rkmRVJj1Tke0M=";
      "flate2-1.0.28" = "sha256-j6T/3yNxefDFi6yyPVi0D0hcvRsLz7EJ/Nypf4WRFvA=";
    };
  };

  nativeBuildInputs = [
    toolchain
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    protobuf_25
    protobuf
    pkg-config
    expat
    fontconfig
    freetype
    freetype.dev
    libGL
    libx11
    libxcursor
    xinput
    libxrandr
    wayland
    libxkbcommon
  ];

  checkFlags = [
    # doesn't work on linux maybe??
    "--skip=cloudsync"
  ];

  runtimeDependencies = [
    expat
    fontconfig
    freetype
    freetype.dev
    libGL
    libx11
    libxcursor
    xinput
    libxrandr
    wayland
    libxkbcommon
  ];

  LD_LIBRARY_PATH = builtins.foldl' (
    a: b: "${a}:${b}/lib"
  ) "${vulkan-loader}/lib" finalAttrs.runtimeDependencies;

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
    export PROTOC=${lib.getExe' protobuf "protoc"} 
  '';

  postInstall = ''
    wrapProgram $out/bin/maxima --prefix LD_LIBRARY_PATH : ${finalAttrs.LD_LIBRARY_PATH}
  '';

  meta = {
    description = "A free and open-source replacement for the EA Desktop Launcher for Linux and Windows.";
    homepage = "https://github.com/ArmchairDevelopers/Maxima";
    license = with lib.licenses; [
      gpl3
    ];
    mainProgram = "maxima";
  };
})

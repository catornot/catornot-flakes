{
  stdenv,
  fetchFromGitHub,
  fetchzip,
  autoPatchelfHook,
  lib,
  llvmPackages,
  libgcc,

  libGL,
  zstd,
  libxkbcommon,
  vulkan-loader,
  xorg,
  alsa-lib,
  wayland,
  glfw,
  udev,
  pkg-config,
  xdg-utils,
  xdg-desktop-portal,
}:
stdenv.mkDerivation rec {
  pname = "satisfactory-3d-map";
  version = "0.9.0";

  src = fetchzip {
    url = "https://github.com/moritz-h/${pname}/releases/download/v${version}/Satisfactory3DMap-Linux.zip";
    sha256 = "sha256-2fkOtsAQpKB4yxRrVWidNpFh7If9uPXB0sMAeOvKsjo=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];
  buildInputs = [
    llvmPackages.openmp.out
    libgcc.lib
    xdg-desktop-portal
  ];
  runtimeDependencies = [
    libGL
    stdenv.cc
    zstd
    libxkbcommon
    vulkan-loader
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    alsa-lib
    wayland
    glfw
    udev
    pkg-config
    xdg-utils
  ];

  installPhase = ''
    runHook preInstall

    install -m755 -D $src/Satisfactory3DMap $out/bin/Satisfactory3DMap 

    runHook postInstall
  '';

  meta = {
    description = " A 3D map savegame tool for the game Satisfactory. ";
    homepage = "https://github.com/moritz-h/satisfactory-3d-map";
    license = lib.licenses.gpl3;
    mainProgram = "Satisfactory3DMap";
  };
}
# stdenv.mkDerivation {
#   pname = "satisfactory-3d-map";
#   version = "1.0.0";

#     src = fetchFromGitHub {
#       owner = "pg9182";
#       repo = "satisfactory-3d-map";
#       rev = "04d6e5b7bd6d18f166ffde7aed3653d5d6700adf";
#       sha256 = "sha256-Y0oDQYUnsChdRyId73paTTgJ2k5n0Y3Cn1Y2TeHdwDo=";
#     };

#     buildInputs = [

#     # Dear ImGui ecosystem
#       imgui
#       # imgui_club        # may need to be packaged manually
#       implot            # ImPlot3D is usually not in nixpkgs

#       # Graphics / math
#       freetype
#       fp16              # sometimes called fp16 or cpuinfo + fp16 headers
#       glfw
#       glm
#       # glowl             # not commonly packaged; may need custom derivation

#       # Header-only / utilities
#         # icon-font-cpp-headers
#       nlohmann_json
#       fatsort
#       # portable-file-dialogs
#       # pybind11
#       spdlog
#       # tinygltf
#       zlib

#       # File / data formats
#       # valve-vdf         # often not packaged; may need vendoring
#       ];

#   meta = {
#     mainProgram = "Satisfactory3DMap";
#   };
# }

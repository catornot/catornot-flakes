{
  lib,
  stdenv,
  makeDesktopItem,
  fetchgit,
  vulkan-loader,
  mesa,
  qt5,
  glib,
  libpng,
  libjpeg,
  makeWrapper,
  pkg-config,
  cmake,
  libsForQt5,
  libxml2,
  assimp,
  zlib,
  libsysprof-capture,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "MRVN-Radiant";
  version = "0.1.9";

  src = fetchgit {
    url = "https://github.com/${finalAttrs.pname}/${finalAttrs.pname}.git";
    rev = "cdd17d8a6966162fa5e326706ad4e9a3d7964fac";
    sha256 = "sha256-bzSOE/ueOftQerXS05MI9/1bxhOdWi3I1yGleCjM4hw=";
  };

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    cmake
    libsForQt5.wrapQtAppsHook
    libsysprof-capture
  ];
  buildInputs = [
    mesa
    qt5.qtbase
    glib
    libpng
    libjpeg
    libxml2
    assimp
    zlib
    libsysprof-capture
  ];
  # not sure which ones to add but full is a no go because qtwebengine has a cve
  runtimeDependencies = [
    libsForQt5.qt5.qtbase
  ];

  postPatch = ''
  '';

  postInstall = ''
    cp -r ../install/* $out/bin
    wrapProgram $out/bin/${finalAttrs.pname} --prefix LD_LIBRARY_PATH : ${finalAttrs.LD_LIBRARY_PATH}
  '';

  LD_LIBRARY_PATH = builtins.foldl' (
    a: b: "${a}:${b}/lib"
  ) "${vulkan-loader}/lib" finalAttrs.runtimeDependencies;

  cmakeFlags = [
    "-DBUILD_TOOLS=ON"
    "-DBUILD_RADIANT=ON"
    "-DBUILD_PLUGINS=ON"
  ];

  desktopItems = [
    (makeDesktopItem {
      desktopName = finalAttrs.pname;
      name = finalAttrs.pname;
      exec = finalAttrs.meta.mainProgram;
      icon = "${finalAttrs.src}/icons/radiant-src.png";
      type = "Application";
      comment = finalAttrs.meta.description;
      terminal = false;
      categories = [ "Development" ];
      keywords = [
        "3D"
      ];
    })
  ];

  meta = {
    description = "MRVN-Radiant is a fork of netradiant-custom modified for Titanfall and Apex Legends mapping.";
    homepage = "https://github.com/MRVN-Radiant/MRVN-Radiant";
    license = with lib.licenses; [
      lgpl21
      bsd0
      gpl2
    ];
    mainProgram = "radiant";
  };
})

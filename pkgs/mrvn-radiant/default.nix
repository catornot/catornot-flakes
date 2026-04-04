{
  pkgs,
  lib,
  ...
}:
pkgs.stdenv.mkDerivation rec {
  pname = "MRVN-Radiant";
  version = "0.1.9";

  src = pkgs.fetchgit {
    url = "https://github.com/${pname}/${pname}.git";
    rev = "cdd17d8a6966162fa5e326706ad4e9a3d7964fac";
    sha256 = "sha256-bzSOE/ueOftQerXS05MI9/1bxhOdWi3I1yGleCjM4hw=";
  };

  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    copyDesktopItems
    cmake
    gcc
    pkg-config
    keepBuildTree # HACK: otherwise nix will complain about rpath linking to /build/
  ];
  buildInputs = with pkgs; [
    pcre
    libsysprof-capture
    qt5.full
    glib
    libxml2
    zlib
    libpng
    libjpeg
  ];

  postPatch = ''
    mkdir -p $out/bin
    cp -r install/* $out/bin

  '';
  postInstall = ''
    cp -r ../install/* $out/bin
  '';

  cmakeFlags = [
    "-DBUILD_TOOLS=ON"
    "-DBUILD_RADIANT=ON"
    "-DBUILD_PLUGINS=ON"
  ];

  desktopItems = [
    (pkgs.makeDesktopItem {
      desktopName = pname;
      name = pname;
      exec = meta.mainProgram;
      icon = "${src}/icons/radiant-src.png";
      type = "Application";
      comment = meta.description;
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
}

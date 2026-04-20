{
  lib,
  dockerTools,
  writeScriptBin,
  symlinkJoin,
  nswrap,
  nswine,
  bash,
  fontconfig,
  dejavu_fonts,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  gawk,
  glib,
  zlib,
  glibc,
  freetype,
  libffi,
  libuuid,
  ncurses,
  openssl,
  northstar,
  titanfall2,
  self,
  makeFontsConf,
}:
let
  wrapInFolder = name: ''
    if [ -z "$(ls -A $out)" ]; then
      echo "Empty"
    else
      mv $out/* $TMP
      mkdir -p $out/${name}
      mv $TMP/* $out/${name}
    fi
  '';
  mkMnt =
    pkg: mnt:
    symlinkJoin {
      name = mnt;
      paths = [ pkg ];
      postBuild = wrapInFolder mnt;
    };
  entrypoint = (writeScriptBin "entrypoint" (builtins.readFile ./entrypoint.sh));
  mnt-northstar = mkMnt northstar "mnt/northstar";
  mnt-titanfall2 = mkMnt titanfall2 "mnt/titanfall2";
  fontsConf = makeFontsConf {
    fontDirectories = [ dejavu_fonts ];
  };
in
dockerTools.buildLayeredImage {
  name = "northstar-dedicated-docker";
  tag = self.rev or "dev";
  contents = [
    # support
    bash
    fontconfig
    dejavu_fonts
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    # glib
    # zlib
    # freetype
    # glibc
    # glibc.bin
    # libffi
    # libuuid
    # ncurses
    # openssl

    # wine
    nswrap
    nswine
    entrypoint

    # northstar
    # mnt-titanfall2
    mnt-northstar
    # look into what wine expects to maybe fix the crashes
  ];

  fromImage = dockerTools.pullImage {
    imageName = "ubuntu";
    imageDigest = "sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c";
    sha256 = "sha256-Wpf0yKdEWJIWrURX+uyLZnqjJ95IO99subetxl6krY0=";
  };
  # fromImage = dockerTools.pullImage {
  #   imageName = "alpine";
  #   imageDigest = "sha256:310c62b5e7ca5b08167e4384c68db0fd2905dd9c7493756d356e893909057601";
  #   sha256 = "sha256-3F+deVJORHl3JZGUYhaX2Lp1vmHTrCr8HFK0tG4j4Ig=";
  # };
  # fromImage = null;

  extraCommands = ''
    mkdir -p home/northstar
  '';

  config = {
    Env = [
      "WINEPREFIX=/home/northstar/.wine"
      "NSWRAP_EXTWINE=1"
      "WINEDEBUG=-all"
      "WINEDLLOVERRIDES=mscoree,mshtml="
      "FONTCONFIG_FILE=${fontsConf}"
    ];
    WorkingDir = "/home/northstar";
    Entrypoint = [
      "/bin/entrypoint"
    ];
  };
}

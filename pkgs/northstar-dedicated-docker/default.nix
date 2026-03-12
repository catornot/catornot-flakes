{
  dockerTools,
  writeScriptBin,
  bash,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  gawk,
  symlinkJoin,
  nswrap,
  nswine,
  northstar,
  titanfall2,
  self,
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
  entrypoint = (writeScriptBin "entrypoint.sh" (builtins.readFile ./entrypoint.sh));
  mnt-northstar = mkMnt northstar "mnt/northstar";
  mnt-titanfall2 = mkMnt titanfall2 "mnt/titanfall2";
in
dockerTools.buildLayeredImage {
  name = "northstar-dedicated-docker";
  tag = self.rev or "dev";
  contents = [
    bash
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    nswrap
    nswine
    entrypoint
    mnt-northstar
    mnt-titanfall2
  ];

  extraCommands = ''
    mkdir -p tmp
    mkdir -p run
    mkdir -p var
    mkdir -p home
    mkdir -p tmp/northstar
    mkdir -p home/northstar
  '';

  config = {
    WorkingDir = "/home/northstar";
    Entrypoint = [ "/bin/entrypoint.sh" ];
    Env = [
      "WINEPREFIX=/home/northstar/.wine"
      "NSWRAP_EXTWINE=1"
      "WINEDEBUG=-all"
    ];
  };
}

{
  dockerTools,
  writeScriptBin,
  lib,
  buildEnv,
  runtimeShell,
  symlinkJoin,
  nswrap,
  nswine,
  northstar,
  check-hash,
  self,
}:
let
  entrypoint = (writeScriptBin "entrypoint.sh" (builtins.readFile ./entrypoint.sh));
  copy-northstar = lib.getExe (
    check-hash.override {
      original = "/mnt/northstar";
      installed = "${northstar}";
      hashFileName = "r2NorthstarHash";
      useSymlinks = false;
    }
  );
  wrapInFolder = name: ''
    if [ -z "$(ls -A $out)" ]; then
      echo "Empty"
    else
      mv $out/* $TMP
      mkdir -p $out/${name}
      mv $TMP/* $out/${name}
    fi
  '';
  mnt-northstar = symlinkJoin {
    name = "mnt/northstar";
    paths = [ northstar ];
    postBuild = wrapInFolder "mnt/northstar";
  };
in
# layared image is a bit more complicated to setup since it will have by default symlinks to stuff... afaik
dockerTools.buildImage {
  name = "northstar-dedicated-docker";
  tag = self.rev or "dev";
  copyToRoot = buildEnv {
    name = "image-root";
    paths = [
      nswrap
      nswine
      entrypoint
      mnt-northstar
    ];
    pathsToLink = [
      "/bin"
      "/lib"
      "/share"
      "/mnt"
    ];
  };

  # runAsRoot = ''
  #   !${runtimeShell}
  #   mkdir -p /mnt
  #   mkdir -p /mnt/northstar
  #   ${copy-northstar}
  # '';

  config = {
    WorkingDir = "/home/northstar";
    Volumes = {
      "/home/northstar" = { };
    };
    Entrypoint = [ "entrypoint.sh" ];
    Env = [
      "WINEPREFIX=/home/northstar/.wine"
      "NSWRAP_EXTWINE=1"
    ];
  };
}

{
  lib,
  symlinkJoin,
}:

let
  isEmpty = list: builtins.length list == 0;

  wrapInFolder = name: ''
    if [ -z "$(ls -A $out)" ]; then
      echo "Empty"
    else
      mv $out/* $TMP
      mkdir -p $out/${name}
      mv $TMP/* $out/${name}
    fi
  '';
in
lib.makeOverridable (
  {
    northstar-packages ? [ ],
    northstar-mods ? [ ],
    northstar-plugins ? [ ],
    northstar-custom ? [ ],
    name ? "R2Northstar",
  }:
  let
    packages-linked = symlinkJoin {
      name = "packages-${name}";
      paths = northstar-packages;
      postBuild = wrapInFolder "packages";
    };
    mods-linked = symlinkJoin {
      name = "mods-${name}";
      paths = northstar-mods;
      postBuild = wrapInFolder "mods";
    };
    plugins-linked = symlinkJoin {
      name = "plugins-${name}";
      paths = northstar-plugins;
      postBuild = wrapInFolder "plugins";
    };
  in
  symlinkJoin {
    name = name;
    paths =
      northstar-custom
      ++ (lib.optional (!isEmpty northstar-packages) packages-linked)
      ++ (lib.optional (!isEmpty northstar-mods) mods-linked)
      ++ (lib.optional (!isEmpty northstar-plugins) plugins-linked);
    postBuild = wrapInFolder name;
  }
)

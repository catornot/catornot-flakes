{
  titanfall2,
  r2overlay,
  northstar,
  northstar-mods ? [ ],
  northstar-packages ? [ ],
  northstar-plugins ? [ ],
  northstar-extras ? [ ],
  symlinkJoin,
  makeR2Northstar,
  writeTextDir,
}:
symlinkJoin {
  name = "northstar-dedicated";
  paths =
    let
      r2northstar = (
        makeR2Northstar {
          inherit
            northstar-mods
            northstar-packages
            northstar-plugins
            northstar-extras
            ;
        }
      );
    in
    [
      titanfall2
      r2overlay
      northstar
      r2northstar
      (writeTextDir "r2NorthstarHash" "${r2northstar}")
    ];
}

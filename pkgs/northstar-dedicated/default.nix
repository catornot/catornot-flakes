{
  titanfall2,
  r2overlay,
  northstar,
  northstar-mods ? [ ],
  northstar-packages ? [ ],
  northstar-plugins ? [ ],
  northstar-extras ? [ ],
  server-settings ? { },
  symlinkJoin,
  makeR2Northstar,
  writeTextDir,
  writeText,
  lib,
}:
let
  autoexec_ns_server =
    settings:
    writeText "autoexec_ns_server.cfg" (
      builtins.concatStringsSep "\n" (lib.mapAttrsToList (var-name: var: "${var-name} ${var}") settings)
    );
in
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

  postBuild = ''
    # remove Northstar.Client since this derivation is made for servers we don't need client # TODO: move this to the northstar derivation maybe?
    rm -r $out/R2Northstar/mods/Northstar.Client

    rm $out/R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg

    cp "${autoexec_ns_server server-settings}" $out/R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg

  '';
}

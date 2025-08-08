{
  stdenvNoCC,
  wine,
  xvfb-run,
  lib,
  writeScriptBin,
  fetchFromGitHub,
  symlinkJoin,
  buildGoModule,
}@inputs:
let
  wine-custom = inputs.wine.overrideAttrs (old: {
    src = fetchFromGitHub {
      owner = "pg9182";
      repo = "nsdockerwine2";
      rev = "2dd1765e4842ba0b1b71d800dc3f45344b8b6b6b";
      sha256 = "sha256-BM+tI7nYsWBahUPSRRBk9OcHG/DbUWm8Q5RjrIq0yGI=";
    };

    patches = [ ];

    meta.mainProgram = "wine";
  });
  wine64 = symlinkJoin {
    name = "wine64";
    paths = [
      wine-custom
      # inputs.wine64
    ];
  };
  wine-name = "wine";

  nswine = buildGoModule {
    pname = "nswine";
    version = "1.0.0";
    src = "${
      fetchFromGitHub {
        owner = "pg9182";
        repo = "nsdockerwine2";
        rev = "c412fb15ef20ebb6ba674796ac527a558942772a";
        sha256 = "sha256-Y0oDQYUnsChdRyId73paTTgJ2k5n0Y3Cn1Y2TeHdwDo=";
      }
    }/nswine";

    vendorHash = "sha256-8B1nbk0ZaYEuujSsdF+KgXFimQdj8JAujQj0af6ECfM=";

    patches = [
      ./remove_extra.patch
    ];
  };
in
stdenvNoCC.mkDerivation {
  pname = "nswine-env";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    wine64
    nswine
  ];
  buildInputs = [
  ];

  phases = [ "buildPhase" ];
  buildPhase = "
      # alias wine64=${wine64}/bin/wine
      export WINEARCH=win64 WINEDLLOVERRIDES=\"mscoree,mshtml,winemenubuilder.exe=\"
      export WINEPREFIX=$out/wine
      mkdir -p $out/wine
      mkdir -p $out/wine/bin
      ${lib.getExe' wine64 wine-name} wineboot --init
      ${lib.getExe' wine64 wine-name} reg add 'HKCU\\Software\\Wine' /v 'Version' /t REG_SZ /d 'win10' /f
      ${lib.getExe' wine64 wine-name} reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Audio' /t REG_SZ /d '' /f
      ${lib.getExe' wine64 wine-name} reg add 'HKCU\\Software\\Wine\\WineDbg' /v 'ShowCrashDialog' /t REG_DWORD /d 0 /f
      ${lib.getExe' wine64 wine-name} reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Graphics' /t REG_SZ /d 'null' /f
      ${lib.getExe' wine64 wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mscoree' /t REG_SZ /d '' /f
      ${lib.getExe' wine64 wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mshtml' /t REG_SZ /d '' /f
      ${lib.getExe' wine64 wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'winemenubuilder' /t REG_SZ /d '' /f
      ${lib.getExe' wine64 wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'd3d11' /t REG_SZ /d 'native' /f
      ${lib.getExe' wine64 wine-name} wineboot --shutdown --force
      ${lib.getExe' wine64 wine-name} wineboot --kill --force

      mkdir $TMP/bin
      mkdir $out/bin
      mkdir $TMP/lib
      mkdir $TMP/lib/wine
      mkdir $TMP/lib/wine/x86_64-windows
      mkdir $TMP/include 
      mkdir $TMP/share 
      cp -r ${wine64}/bin/* $TMP/bin 
      cp -r ${wine64}/bin/* $out/bin 
      cp -r ${wine64}/lib/wine/x86_64-unix $TMP/lib/wine/x86_64-unix
      cp -r ${wine64}/lib/wine/x86_64-windows/* $TMP/lib/wine/x86_64-windows
      cp -r ${wine64}/include/* $TMP/include
      cp -r ${wine64}/share/* $TMP/share
      
      # rm $TMP/lib/wine/x86_64-windows/explorer.exe
      # cp ${wine64}/lib/wine/x86_64-windows/explorer.exe $TMP/lib/wine/x86_64-windows/explorer.exe
      # chmod 777 $TMP/lib/wine/x86_64-windows/explorer.exe
      # NSWINE_UNSAFE=1 nswine --prefix $TMP

      cp -r $TMP/lib $out/lib
      ln -s $out/lib $out/lib64

      # rm $out/bin/${wine-name}
      # cp ${writeScriptBin wine-name ''${xvfb-run}/bin/xvfb-run ${wine64}/bin/${wine-name} "$@"''}/bin/${wine-name} $out/bin/${wine-name}
  ";
}

# makeWrapper $out/bin/wine64 \
#   --suffix PATH : ${
#   lib.makeBinPath [
#     xdg-utils
#     xvfb-run
#   ]
# }

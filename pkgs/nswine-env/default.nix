{
  stdenvNoCC,
  wine,
  wineWow64Packages,
  xvfb-run,
  lib,
  writeScriptBin,
  fetchFromGitHub,
  symlinkJoin,
  buildGoModule,
}@inputs:
let
  wine-custom = inputs.wineWow64Packages.stable.overrideAttrs (old: {
    src = fetchFromGitHub {
      owner = "pg9182";
      repo = "nsdockerwine2";
      rev = "2dd1765e4842ba0b1b71d800dc3f45344b8b6b6b";
      sha256 = "sha256-BM+tI7nYsWBahUPSRRBk9OcHG/DbUWm8Q5RjrIq0yGI=";
    };

    patches = [ ];

    meta.mainProgram = "wine";
  });
  wine-ns = symlinkJoin {
    name = "wine-ns";
    paths = [
      wine-custom
      # inputs.wine64
      # wineWow64Packages.stable
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
    # wine64
    nswine
  ];
  buildInputs = [
  ];

  phases = [ "buildPhase" ];
  buildPhase = "
      export XDG_CACHE_HOME=\"\$(mktemp -d)\"      

      export WINEARCH=win64 WINEDLLOVERRIDES=\"mscoree,mshtml,winemenubuilder.exe=\"
      export WINEPREFIX=$out/wine
      mkdir -p $out/wine
      mkdir -p $out/wine/bin
      # ${lib.getExe' wine-ns wine-name} wineboot --init
      # ${lib.getExe' wine-ns wine-name} reg add 'HKCU\\Software\\Wine' /v 'Version' /t REG_SZ /d 'win10' /f
      # ${lib.getExe' wine-ns wine-name} reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Audio' /t REG_SZ /d '' /f
      # ${lib.getExe' wine-ns wine-name} reg add 'HKCU\\Software\\Wine\\WineDbg' /v 'ShowCrashDialog' /t REG_DWORD /d 0 /f
      # ${lib.getExe' wine-ns wine-name} reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Graphics' /t REG_SZ /d 'null' /f
      # ${lib.getExe' wine-ns wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mscoree' /t REG_SZ /d '' /f
      # ${lib.getExe' wine-ns wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mshtml' /t REG_SZ /d '' /f
      # ${lib.getExe' wine-ns wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'winemenubuilder' /t REG_SZ /d '' /f
      # ${lib.getExe' wine-ns wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'd3d11' /t REG_SZ /d 'native' /f
      # ${lib.getExe' wine-ns wine-name} wineboot --shutdown --force
      # ${lib.getExe' wine-ns wine-name} wineboot --kill --force

      mkdir -p $TMP/bin
      mkdir -p $out/bin
      mkdir -p $TMP/lib
      mkdir -p $TMP/out
      mkdir -p $TMP/lib/wine
      mkdir -p $TMP/lib/wine/x86_64-windows
      mkdir -p $TMP/include 
      mkdir -p $TMP/share 
      cp -r ${wine-ns}/bin/* $TMP/bin 
      cp -r ${wine-ns}/lib/wine/x86_64-unix $TMP/lib/wine/x86_64-unix
      cp -r ${wine-ns}/lib/wine/x86_64-windows/* $TMP/lib/wine/x86_64-windows
      # cp -r ${wine-ns}/lib/wine/x86_64-unix $TMP/lib/wine/i386-unix
      # cp -r ${wine-ns}/lib/wine/x86_64-windows/* $TMP/lib/wine/i386-windows
      # cp -r ${wine-ns}/lib/wine/i386-unix $TMP/lib/wine/x86_64-unix
      # cp -r ${wine-ns}/lib/wine/i386-windows/* $TMP/lib/wine/x86_64-windows
      # cp -r ${wine-ns}/lib/wine/i386-unix $TMP/lib/wine/i386-unix
      # cp -r ${wine-ns}/lib/wine/i386-windows/* $TMP/lib/wine/i386-windows
      cp -r ${wine-ns}/include/* $TMP/include
      cp -r ${wine-ns}/share/* $TMP/share
      
      # rm $TMP/lib/wine/x86_64-windows/explorer.exe
      # cp ${wine-ns}/lib/wine/x86_64-windows/explorer.exe $TMP/lib/wine/x86_64-windows/explorer.exe
      # chmod 777 $TMP/lib/wine/x86_64-windows/explorer.exe
      # NSWINE_UNSAFE=1 nswine --prefix $TMP --output $out/wine2

      
      $TMP/bin/${wine-name} wineboot --init
      $TMP/bin/${wine-name} reg add 'HKCU\\Software\\Wine' /v 'Version' /t REG_SZ /d 'win10' /f
      $TMP/bin/${wine-name} reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Audio' /t REG_SZ /d '' /f
      $TMP/bin/${wine-name} reg add 'HKCU\\Software\\Wine\\WineDbg' /v 'ShowCrashDialog' /t REG_DWORD /d 0 /f
      $TMP/bin/${wine-name} reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Graphics' /t REG_SZ /d 'null' /f
      $TMP/bin/${wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mscoree' /t REG_SZ /d '' /f
      $TMP/bin/${wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mshtml' /t REG_SZ /d '' /f
      $TMP/bin/${wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'winemenubuilder' /t REG_SZ /d '' /f
      $TMP/bin/${wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'd3d11' /t REG_SZ /d 'native' /f
      $TMP/bin/${wine-name} wineboot --shutdown --force
      $TMP/bin/${wine-name} wineboot --kill --force
      
      rm $out/wine/dosdevices/z: # hoppefully 

      # hmm
      rm $out/wine/drive_c/windows/explorer.exe
      cp $TMP/lib/wine/x86_64-windows/explorer.exe $out/wine/drive_c/windows/explorer.exe

      # remove wine gecko
      rm -r $out/wine/drive_c/windows/system32/gecko

      cp -r $TMP/lib $out/lib

      cp -r ${wine-ns}/bin/* $out/bin/ 
      # cp -r ${wine-ns}/bin/wineserver $out/bin/wineserver 
      # rm $out/bin/${wine-name}
      # install -m775 -D ${wine-ns}/bin/${wine-name} $out/bin/${wine-name}
      # cp ${writeScriptBin wine-name ''${xvfb-run}/bin/xvfb-run ${wine-ns}/bin/${wine-name} "$@"''}/bin/${wine-name} $out/bin/${wine-name}
  ";
}

# makeWrapper $out/bin/wine64 \
#   --suffix PATH : ${
#   lib.makeBinPath [
#     xdg-utils
#     xvfb-run
#   ]
# }

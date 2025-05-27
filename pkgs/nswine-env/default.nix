{
  stdenvNoCC,
  wine64,
}:
  stdenvNoCC.mkDerivation {
    pname = "nswine-env";
    version = "0.1.0";

    src = ./.;

    nativeBuildInputs = [
      wine64
    ];
    buildInputs = [
    ];

    noUnpackPhase = "";
    buildPhase = "
      export WINEARCH=win64 WINEDLLOVERRIDES=\"mscoree,mshtml,winemenubuilder.exe=\"
      export WINEPREFIX=$out/wine
      mkdir -p $out/wine
      mkdir -p $out/wine/bin
      wine64 wineboot --init
      wine64 reg add 'HKCU\\Software\\Wine' /v 'Version' /t REG_SZ /d 'win10' /f
      wine64 reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Audio' /t REG_SZ /d '' /f
      wine64 reg add 'HKCU\\Software\\Wine\\WineDbg' /v 'ShowCrashDialog' /t REG_DWORD /d 0 /f
      wine64 reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Graphics' /t REG_SZ /d 'null' /f
      wine64 reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mscoree' /t REG_SZ /d '' /f
      wine64 reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mshtml' /t REG_SZ /d '' /f
      wine64 reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'winemenubuilder' /t REG_SZ /d '' /f
      wine64 reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'd3d11' /t REG_SZ /d 'native' /f
      wine64 wineboot --shutdown --force
      wine64 wineboot --kill --force
      ln -s ${wine64}/bin/ $out/bin 
      ln -s ${wine64}/lib/ $out/lib64 
      ln -s ${wine64}/include $out/include
      ln -s ${wine64}/share $out/share
    ";
  }

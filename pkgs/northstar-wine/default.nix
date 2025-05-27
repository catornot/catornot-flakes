{
  nswrap,
  stdenvNoCC,
  writers,
  wine64,
}:
let
  ns-wine = stdenvNoCC.mkDerivation {
    pname = "northstar-wine";
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
  };
in
writers.writeRustBin "nswine-run" { } # rust
  ''
    use std::env;

    fn main() -> Result<(), Box<dyn std::error::Error>> {
      println!("wrapper startup!");

      let envs = [
        ("WINEARCH", r#"win64 WINEDLLOVERRIDES=\"mscoree,mshtml,winemenubuilder.exe=\""#),
        ("WINEPREFIX", "${ns-wine}/wine"),
        ("NSWRAP_DEBUG", "1"),
        ("NSWRAP_EXTWINE", "1"),
        ("NSWRAP_RUNTIME", "${ns-wine}"),
        ("PATH", "${wine64}/bin"),
      ];

      let mut args = env::args();
      _ = args.next();
      
      std::process::Command::new(dbg!("${nswrap}/bin/nswrap").to_string())
        .envs(envs)
        .current_dir(args.next().ok_or("include the path to the northstar install pls")?.to_string())
        .arg("-dedicated")
        .args(args)
        .spawn()?
        .wait()?;

      println!("wrapper done!");

      Ok(())
    }
  ''

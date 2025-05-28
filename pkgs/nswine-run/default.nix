{
  nswrap,
  writers,
  wine64,
  nswine-env-path,
}:
writers.writeRustBin "nswine-run" { } # rust
  ''
    use std::env;

    fn main() -> Result<(), Box<dyn std::error::Error>> {
      println!("wrapper startup!");

      let envs = [
        ("WINEARCH", r#"win64 WINEDLLOVERRIDES=\"mscoree,mshtml,winemenubuilder.exe=\""#),
        ("WINEPREFIX", "${nswine-env-path}"),
        ("NSWRAP_DEBUG", "1"),
        ("NSWRAP_EXTWINE", "1"),
        ("PATH", "${wine64}/bin"),
      ];

      let mut args = env::args();
      _ = args.next();
      let path_arg = args.next().ok_or("include the path to the northstar install pls")?.to_string();

      println!("tf2 dir is : {path_arg}");

      let args = args.inspect(|arg| println!("with arg: {arg}")).collect::<Vec<_>>();
      
      std::process::Command::new(dbg!("${nswrap}/bin/nswrap").to_string())
        .envs(envs)
        .current_dir(path_arg)
        .arg("-dedicated")
        .args(args)
        .spawn().map_err(|err| format!("can't spawn: {err:?}"))?
        .wait().map_err(|err| format!("can't wait: {err:?}"))?;

      println!("wrapper done!");

      Ok(())
    }
  ''

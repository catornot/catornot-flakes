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

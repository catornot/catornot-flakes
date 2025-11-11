{
  nswrap,
  writers,
  nswine-env-path,
  xvfb-run,
  bash,
  lib,
}:
writers.writeRustBin "nswine-run" { } # rust
  ''
    use std::env;
    use std::path::PathBuf;

    fn main() -> Result<(), Box<dyn std::error::Error>> {
      println!("wrapper startup!");

      let envs = [
        ("WINEARCH", r#"win64"#),
        ("WINEDLLOVERRIDES", r#""mscoree,mshtml,winemenubuilder.exe=\""#),
        ("WINEDEBUG", r#"+msgbox,fixme-secur32,fixme-bcrypt,fixme-ver,err-wldap32,err-kerberos,err-ntlm"#),
        ("WINEPREFIX", "${nswine-env-path}"),
        ("NSWRAP_RUNTIME", "${nswine-env-path}"),
        ("NSWRAP_DEBUG", "1"),
        ("NSWRAP_EXTWINE", "1"),
        // ("PATH", "${nswine-env-path}"),
        ("XDG_RUNTIME_DIR", "${nswine-env-path}")
      ];

      let mut args = env::args();
      _ = args.next();
      let path_arg = PathBuf::from(args.next().ok_or("include the path to the northstar install pls")?.to_string());

      let nswrap = PathBuf::from("${nswine-env-path}").parent().expect("nswrap nooo").join("bin").join("nswrap");
      println!("tf2 dir is : {} and it exists? {}", path_arg.display(), path_arg.exists());
      println!("nswrap path is : {} and it exists? {}", nswrap.display(), nswrap.exists());

      let args = args.inspect(|arg| println!("with arg: {arg}")).collect::<Vec<_>>();
      
      // std::process::Command::new("${lib.getExe bash}")
      // std::process::Command::new(nswrap)
      std::process::Command::new("${nswine-env-path}/bin/wine".to_string())
      // std::process::Command::new("${xvfb-run}/bin/xvfb-run".to_string())
        // .arg("${nswine-env-path}/bin/wine")
        // .arg("${nswine-env-path}/bin/wine")
        // .arg("wine")
        .envs(envs)
        .current_dir(path_arg)
        // .arg("wine")
        .arg("NorthstarLauncher.exe")
        .arg("-dedicated")
        .args(args)
        .spawn().map_err(|err| format!("can't spawn: {err:?}"))?
        .wait().map_err(|err| format!("can't wait: {err:?}"))?;

      println!("wrapper done!");

      Ok(())
    }
  ''

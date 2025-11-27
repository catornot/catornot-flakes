{
  installed ? "",
  original ? "",
  hashFileName ? "",
  writers,
}:
writers.writeRustBin "check-hash" { } # rust
  ''
    use std::{env, io};
    use std::path::{PathBuf, Path};
    use std::fs::{remove_dir_all, read_to_string, copy};
    use std::io::Write;

    const INSTALLED: &str = "${installed}";
    const ORIGINAL: &str = "${original}";
    const HASH_FILE_NAME: &str = "${hashFileName}";

    fn main() -> Result<(), Box<dyn std::error::Error>> {
      let (installed, original, hash_file_name) = if INSTALLED == "" || ORIGINAL == "" || HASH_FILE_NAME == "" {
          if INSTALLED == ORIGINAL || ORIGINAL == HASH_FILE_NAME  {
            let mut args = env::args();
            _ = args.next();
            (args.next().ok_or("include installed")?.to_string(), args.next().ok_or("include original")?.to_string(), args.next().ok_or("include hash file name")?.to_string())
          } else {
            return Err("vars are paritallly empty".into())
          }
      } else {
        (INSTALLED.to_string(), ORIGINAL.to_string(), HASH_FILE_NAME.to_string())        
      };

      if !PathBuf::from(&installed).join(&hash_file_name).exists() || read_to_string(PathBuf::from(&installed).join(&hash_file_name))? != read_to_string(PathBuf::from(&original).join(&hash_file_name))? {
        _ = writeln!(std::io::stdout(), "found missmatch; replacing");
        _ = remove_dir_all(&installed);
        // TODO: do not copy out of symlinks
        copy_dir_all(original, installed)?;
      } else {
        _ = writeln!(std::io::stdout(), "all good");
      }

      Ok(())
    }

    fn copy_dir_all(src: impl AsRef<Path>, dst: impl AsRef<Path>) -> io::Result<()> {
        use std::fs;
        use std::os::unix::fs as unix_fs;
        fs::create_dir_all(&dst)?;
        for entry in fs::read_dir(src)? {
            let entry = entry?;
            let ty = entry.file_type()?;
            if ty.is_dir() && !ty.is_symlink() {
                copy_dir_all(entry.path(), dst.as_ref().join(entry.file_name()))?;
            } else {
                unix_fs::symlink(entry.path(), dst.as_ref().join(entry.file_name()))?;
            }
        }
        Ok(())
    }
  ''

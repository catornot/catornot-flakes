{
  stdenvNoCC,
  wine64,
  wineWowPackages,
  wineWow64Packages,
  xvfb-run,
  lib,
  writeScriptBin,
  fetchFromGitHub,
  symlinkJoin,
  buildGoModule,
  bash,
  writeText,
}@inputs:
let
  wine-custom = inputs.wineWow64Packages.base.overrideAttrs (old: {
    src = fetchFromGitHub {
      owner = "pg9182";
      repo = "nsdockerwine2";
      rev = "2dd1765e4842ba0b1b71d800dc3f45344b8b6b6b";
      sha256 = "sha256-BM+tI7nYsWBahUPSRRBk9OcHG/DbUWm8Q5RjrIq0yGI=";
    };

    patches = [ ];

    # meta.mainProgram = "wine";
  });
  wine-real = inputs.wineWow64Packages.base.overrideAttrs (old: {
    src = fetchFromGitHub {
      owner = "pg9182";
      repo = "nsdockerwine2";
      rev = "885446556ce443b496e368b8f2c68807dcc7df0f";
      sha256 = "sha256-6n06LO36Epq3c1mWH1CJJEI8Hk/zObIttoiDPUGIBUQ=";
    };

    patches = [ ];

    # meta.mainProgram = "wine";
  });
  wine-ns = wineWow64Packages.base;
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
      # (writeText "patch.patch" ''
      #   diff --git a/nswine/nswine.go b/nswine/nswine.go
      #   index 87a462e3660..dc7ae9e24ee 100644
      #   --- a/nswine.go
      #   +++ b/nswine.go
      #   @@ -550,8 +550,8 @@ func run() error {

      #    	wineEnv := append(os.Environ(), "WINEPREFIX="+*Output, "WINEARCH=win64", "USER=nswrap")

      #   -	slog.Info("creating wineprefix")
      #   -	{
      #   +	if *Vendor {
      #   +		slog.Info("creating wineprefix")
      #    		winedebug := "err-ole,fixme-actctx"
      #    		if *Debug {
      #    			winedebug += ",+loaddll"
      #   @@ -571,10 +571,10 @@ func run() error {
      #    		// there's an i386 binary somewhere getting called by wine.inf, causing wine to try and use the wow64 loader, which we deleted earlier
      #    	}

      #   -	slog.Info("disabling automatic wineprefix updates")
      #   -	if err := os.WriteFile(filepath.Join(*Output, ".update-timestamp"), []byte("disable\n"), 0644); err != nil {
      #   -		return err
      #   -	}
      #   +	// slog.Info("disabling automatic wineprefix updates")
      #   +	// if err := os.WriteFile(filepath.Join(*Output, ".update-timestamp"), []byte("disable\n"), 0644); err != nil {
      #   +	// 	return err
      #   +	// }

      #    	if *Optimize {
      #    		// TODO: clean up empty dirs
      #   @@ -591,22 +591,23 @@ func run() error {
      #    	}

      #    	// TODO: remove this
      #   -	filepath.WalkDir(*Prefix, func(path string, d fs.DirEntry, err error) error {
      #   -		slog.Debug("wine file", "path", path)
      #   -		return nil
      #   -	})
      #   -	filepath.WalkDir(*Output, func(path string, d fs.DirEntry, err error) error {
      #   -		slog.Debug("wineprefix file", "path", path)
      #   -		return nil
      #   -	})
      #   +	// filepath.WalkDir(*Prefix, func(path string, d fs.DirEntry, err error) error {
      #   +	// 	slog.Debug("wine file", "path", path)
      #   +	// 	return nil
      #   +	// })
      #   +	// filepath.WalkDir(*Output, func(path string, d fs.DirEntry, err error) error {
      #   +	// 	slog.Debug("wineprefix file", "path", path)
      #   +	// 	return nil
      #   +	// })

      #    	// TODO: replace this with a go impl
      #   -	if tmp, err := exec.Command("du", "-sh", *Prefix).Output(); err == nil {
      #   -		slog.Info(string(bytes.TrimSpace(tmp)))
      #   -	}
      #   -	if tmp, err := exec.Command("du", "-sh", *Output).Output(); err == nil {
      #   -		slog.Info(string(bytes.TrimSpace(tmp)))
      #   -	}
      #   -
      #   -	return errors.ErrUnsupported
      #   +	// if tmp, err := exec.Command("du", "-sh", *Prefix).Output(); err == nil {
      #   +	// 	slog.Info(string(bytes.TrimSpace(tmp)))
      #   +	// }
      #   +	// if tmp, err := exec.Command("du", "-sh", *Output).Output(); err == nil {
      #   +	// 	slog.Info(string(bytes.TrimSpace(tmp)))
      #   +	// }
      #   +
      #   +	// return errors.ErrUnsupported
      #   +	return nil;
      #    }
      # '')
    ];
  };
in
stdenvNoCC.mkDerivation {
  pname = "nswine";
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
      export HOME=\"\$(mktemp -d)\"

      mkdir $out
      cp -r --no-preserve=ownership ${wine-ns}/* $out
      chmod -R +rwXrwXrwX $out

      mkdir $TMP/wine
      
      NSWINE_UNSAFE=1 nswine --prefix $out --output $TMP/wine -optimize -debug
  ";
}

# makeWrapper $out/bin/wine64 \
#   --suffix PATH : ${
#   lib.makeBinPath [
#     xdg-utils
#     xvfb-run
#   ]
# }

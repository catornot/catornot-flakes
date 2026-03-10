{
  lib,
  stdenv,
  rustPlatform,
  fetchNpmDeps,
  cargo-tauri,
  glib-networking,
  nodejs,
  npmHooks,
  typescript,
  openssl,
  pkg-config,
  webkitgtk_4_1,
  wrapGAppsHook4,
  makeDesktopItem,
  fetchFromGitHub,
  applyPatches,
  libappimage,
  runCommand,
  jq,
  symlinkJoin,
}:

let
  src = applyPatches {
    src = fetchFromGitHub {
      owner = "R2NorthstarTools";
      repo = pname;
      tag = "v${version}";
      hash = "sha256-i/6ywfXlUOBmiE9MhRYsDCt8eNkIOZHRxTJwWTmZ4Ms=";
    };
    patches = [
    ];
  };
  pname = "FlightCore";
  version = "3.2.1";
  mergedNpmDeps =
    let
      srcTop = src; # top deps folder
      srcVue = "${src}/src-vue"; # vue deps folder
    in
    runCommand "merged-npm-deps"
      {
        buildInputs = [
          nodejs
          jq
        ];
      }
      ''
        mkdir -p $out
        mkdir -p $TMPDIR/merged
        # Copy vue package.json dependencies into top's package.json
        jq -s '.[0] * .[1]' \
           ${srcTop}/package.json \
           ${srcVue}/package.json > $TMPDIR/merged/package.json
        chmod +rw $TMPDIR/merged -R
        cd $TMPDIR/merged
        npm install --package-lock-only
        cp $TMPDIR/merged/* $out
      '';
  joined = symlinkJoin {
    name = pname;
    paths = [
      ./.
      src
    ];
  };
in

rustPlatform.buildRustPackage (finalAttrs: {

  inherit version pname;
  src = joined;

  cargoHash = "sha256-ILsRsYHO1OMyfORxrUkr1jyjncLCGag+KefrWHmHpqQ=";

  # Assuming our app's frontend uses `npm` as a package manager
  npmDeps = fetchNpmDeps {
    src = joined;
    hash = "sha256-RPpmw1AKncTNtPL+RvpS6X2zGAbyljY++aP0AObjsg8=";
  };

  nativeBuildInputs = [
    # Pull in our main hook
    cargo-tauri.hook

    # Setup npm
    nodejs
    npmHooks.npmConfigHook
    typescript

    # Make sure we can find our libraries
    pkg-config
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    wrapGAppsHook4
    libappimage
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    glib-networking # Most Tauri apps need networking
    openssl
    webkitgtk_4_1
  ];

  buildPhase = ''
    export NODE_PATH=$npmDeps/lib/node_modules
    npx tauri build
  '';

  # Set our Tauri source directory
  cargoRoot = "src-tauri";
  # And make sure we build there too
  buildAndTestSubdir = finalAttrs.cargoRoot;

  desktopItems = [
    (makeDesktopItem {
      desktopName = finalAttrs.pname;
      name = finalAttrs.pname;
      exec = finalAttrs.meta.mainProgram;
      icon = "${finalAttrs.src}/docs/assets/Square310x310Logo.png";
      type = "Application";
      comment = finalAttrs.meta.description;
      terminal = false;
      categories = [ ];
      keywords = [
        ""
      ];
    })
  ];

  meta = {
    description = "Installer/Updater/Launcher for Northstar";
    homepage = "https://github.com/R2NorthstarTools/FlightCore";
    license = with lib.licenses; [
      mit
    ];
    mainProgram = "FlightCore";
  };
})

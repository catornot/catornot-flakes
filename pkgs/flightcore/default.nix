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
  symlinkJoin,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "FlightCore";
  version = "3.2.0";

  src = applyPatches {
    src = fetchFromGitHub {
      owner = "R2NorthstarTools";
      repo = finalAttrs.pname;
      tag = "v${finalAttrs.version}";
      hash = "sha256-MFnW9cXFzqmdtC31r8cRcihV3NjGAC6+2/DnNVMheCI=";
    };
    patches = [
      ./bundle_app.patch
    ];
  };

  cargoHash = "sha256-qh8mHDgIwh20I8P8rx25CZIVB8X4ZtY7/lyGQ3xy/7k=";

  # Assuming our app's frontend uses `npm` as a package manager
  npmDeps = "${symlinkJoin {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    paths = [
      (fetchNpmDeps {
        name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps-top";
        inherit (finalAttrs) src;
        hash = "sha256-6k582aTReT9JLXmIw4i3iccLSVCKsnCthVfeF8vrsp4=";
      })
      (fetchNpmDeps {
        name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps-vue";
        src = "${finalAttrs.src}/src-vue";
        hash = "sha256-QhUPkCBK1kcAF7gByFxlg8Ca9PLF3evCl0QYEPP/Q2c=";
      })
    ];
  }}";

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

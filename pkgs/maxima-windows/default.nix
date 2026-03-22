{
  writeScript,
  maxima,
  pkgsCross,
  wineWow64Packages,
  pkgsBuildHost,
  buildPackages,
  pkg-config,
  llvmPackages,
  callPackage,
}:
let
  toolchain = pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
  cross = pkgsCross.x86_64-windows;
  clang-cl = callPackage ./clang-cl.nix { inherit (cross) windows; };
  rustc = callPackage ./msvc-rust.nix {
    inherit clang-cl;
    inherit (cross) windows;
    rustc = toolchain;
  };
in
(maxima.override {
  toolchain = toolchain;
  rustc = rustc;
}).overrideAttrs
  (old: {
    buildInputs = [
      # pkgsCross.mingwW64.stdenv.cc
      # pkgsCross.mingwW64.windows.pthreads
      # pkgsCross.mingwW64.windows.mingw_w64_headers
      # pkgsCross.mingwW64.zstd
      cross.windows.sdk
    ];

    nativeBuildInputs = old.nativeBuildInputs ++ [
      # We need Wine to run tests:
      wineWow64Packages.stable
      toolchain
      pkg-config
      llvmPackages.clang-unwrapped
      llvmPackages.bintools-unwrapped
    ];

    # postPatch = old.postPatch + ''
    #   export ZSTD_SYS_USE_PKG_CONFIG=1
    # '';

    postPatch = old.postPatch + ''
      rustc --version
    '';

    postInstall = "";

    doCheck = false; # then we can remove the runner

    cargoBuildFlags = [
      "--package"
      "maxima-bootstrap"
      "--target"
      "x86_64-pc-windows-msvc"
    ];

    # Tells Cargo that we're building for Windows.
    # (https://doc.rust-lang.org/cargo/reference/config.html#buildtarget)
    CARGO_BUILD_TARGET = "x86_64-pc-windows-msvc";
    CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER = "${llvmPackages.clang-unwrapped}/bin/lld-link";
    CC_x86_64-pc-windows-msvc = "${llvmPackages.clang-unwrapped}/bin/clang-cl";

    meta.mainProgram = null;
  })

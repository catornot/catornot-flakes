{
  stdenv,
  fetchFromGitHub,
  wineWow64Packages,
  keepBuildTree,
  pkgsCross,
  pkgs-win ? pkgsCross.mingwW64,
}:
stdenv.mkDerivation (final: {
  pname = "sere";
  version = "0.1.0";

  src = "${fetchFromGitHub {
    owner = "RoyalBlue1";
    repo = "SERE";
    rev = "9f745176135474e3aa3ded0f4c479021f5e22127";
    sha256 = "sha256-CRnmlYNXCPJN53C0vcYeeICKRrgFwXxIdZX6mKP9R6Y=";
  }}/SERE";

  nativeBuildInputs = [
    wineWow64Packages.waylandFull
    # pkgs-win.cmake
    keepBuildTree
  ];
  buildInputs =
    let
      imgui = pkgs-win.imgui.overrideAttrs (old: {
        # hack to remove non "base" game mods
        buildInputs = [
          pkgs-win.windows.mingw_w64_headers
          # pkgs-win.windows.mcfgthreads
          pkgs-win.windows.pthreads
        ];
      });
    in
    [
      (pkgs-win.rapidjson.overrideAttrs (old: {
        # hack to remove non "base" game mods
        buildInputs = old.buildInputs ++ [
          pkgs-win.windows.mingw_w64_headers
          # pkgs-win.windows.mcfgthreads
          pkgs-win.windows.pthreads
        ];
      }))
      (pkgs-win.implot.overrideAttrs (old: {
        # hack to remove non "base" game mods
        buildInputs = [
          pkgs-win.windows.mingw_w64_headers
          imgui
          pkgs-win.windows.pthreads
        ];
      }))
      pkgs-win.windows.mingw_w64_headers
      # pkgs-win.windows.mcfgthreads
      pkgs-win.windows.pthreads
    ];

  buildPhase = ''
    winemaker --lower-uppercase -icomdlg32 -ishell32 -ishlwapi -iuser32 -igdi32 -iadvapi32 -ld3d9 .
    make
  '';

  meta = {
  };
})

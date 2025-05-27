{
  stdenv,
  fetchFromGitHub,
  glibc,
  libunwind,
  libgnurl,
  dockerTools,
  buildGoModule,
  udev,
  wineWow64Packages,
}:
let
  repo-src = fetchFromGitHub {
    owner = "pg9182";
    repo = "nsdockerwine2";
    rev = "52fa83c23b7a7d11fe949d2fa1d8879966ac18c5";
    sha256 = "sha256-Qmhye26M4ULrqLn3e/F1dxIntO/OXPPd+fVEhOWZ5h4=";
  };
  version = "1.0.0";
in
let
  nswine = buildGoModule {
    pname = "nswine";
    inherit version;
    src = "${repo-src}/nswine";
    vendorHash = "sha256-8B1nbk0ZaYEuujSsdF+KgXFimQdj8JAujQj0af6ECfM=";
  };
in
stdenv.mkDerivation {
  pname = "nswrap";
  inherit version;

  src = repo-src;

  nativeBuildInputs = [
  ];
  buildInputs = [
    glibc
    libunwind
    libgnurl
  ];

  buildPhase = ''
    mkdir -p $out/bin/
    gcc -Wall -Wextra $src/nswrap/nswrap.c -o $out/bin/nswrap
  '';

  # installPhase = ''
  #   install -Dm755 "${nswine}/bin/nswine" "$out/bin/nswine"
  # '';

  meta = {
  };
}

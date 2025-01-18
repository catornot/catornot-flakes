{
  pkg-config,
  openssl,
  lib,
  rustPlatform,
}:
let
in
# why does it need to be so complicated >:(
rustPlatform.buildRustPackage rec {
  pname = "papa";
  version = "4.1.0-rc.4";
  rev = "88c81dee17570711c9dbf6f9d6f8e6fe54d10dba";

  buildInputs = [
    openssl
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  src = builtins.fetchGit {
    url = "https://github.com/AnActualEmerald/papa.git";
    ref = "main";
    rev = rev;
    submodules = true; # whyyyyyy
    allRefs = true;
  };

  meta = {
    description = "A cli mod manager for the Northstar launcher";
    homepage = "https://github.com/AnActualEmerald/papa";
    license = lib.licenses.mit;
    mainProgram = "papa";
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };

  # cargoHash = lib.fakeHash; # uncheck this when you need to change the hash
  cargoHash = "sha256-cBYodPTcS3OilggAQW7dA6sGPnKmDRzLvFvlXRACTPQ=";
  cargoDepsName = pname;
}

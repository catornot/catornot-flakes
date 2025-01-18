{
  pkg-config,
  openssl,
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
let
in
  builtins.fetchurl {
   url = "https://github.com/AnActualEmerald/papa/releases/download/v4.0.0/papa";
   sha256 = "sha256:12gqm4mfvac0cybkdhx9c7617anx377himham06asd4xv8i99ci5";
  }

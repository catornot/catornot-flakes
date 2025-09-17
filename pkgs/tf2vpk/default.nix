{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}:
buildGoModule rec {
  pname = "tf2vpk";
  version = "0.0.4";

  src = fetchFromGitHub {
    owner = "pg9182";
    repo = "tf2vpk";
    rev = "v${version}";
    hash = "sha256-BLvk1a7S95umoKS+0wI1Z82qdVAknwDAnPSQ9geEQHI=";
  };

  vendorHash = "sha256-WQbece2wM+sBhgolDOnq8w2a5FFr0HFwsp4hnUf3NQk=";

  meta = {
    description = "Libraries and tools for working with Titanfall 2 VPKs.";
    homepage = "https://github.com/pg9182/tf2vpk";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ cat_or_not ];
    mainProgram = "tf2-vpkunpack";
  };
}

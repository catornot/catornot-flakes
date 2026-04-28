{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  libgit2,
  ...
}:
let
  libgit2_1-5 = libgit2.overrideAttrs (
    old: finalAttrs: {
      version = "old";

      src = fetchFromGitHub {
        owner = "libgit2";
        repo = "libgit2";
        rev = "v1.5.0";
        hash = "sha256-lXFQo+tt56BFoPgdkTfz6WdIngeotTm+8cAGcBP6XqY=";
      };
    }
  );
in
buildGoModule rec {
  pname = "splitsh-lite";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "splitsh";
    repo = "lite";
    rev = "v${version}";
    hash = "sha256-WMLUg4i02ea4jCv87H/WpNyXGYGyCA3dvSIXmEo1aXs=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libgit2_1-5
  ];

  vendorHash = "sha256-0FmDx2pRBb57HU7zpZ0v6wXdFRwCJPGmiENnVjPBB/w=";

  meta = {
    description = " Split a repository to read-only standalone repositories ";
    homepage = "https://github.com/splitsh/lite";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ cat_or_not ];
    mainProgram = "lite";
  };
}

{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sqformat";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "Bobbyperson";
    repo = finalAttrs.pname;
    tag = "v" + finalAttrs.version;
    hash = "sha256-7QVk/LQb/BFnrz2lCFh8L19M9Za2omArw3YCs/f1bMA=";
  };

  cargoHash = "sha256-/B93mLawURmR1wOf2KrGKnYhtt1y4n+YhPQhWjaQLNw=";

  meta = {
    description = "Formatter for respawn's version of squirrel";
    homepage = "https://github.com/Bobbyperson/sqformat";
    license = with lib.licenses; [
      mit
    ];
    mainProgram = "sqformat";
  };
})

{
  lib,
  stdenvNoCC,
  fetchurl,
  ripunzip,
}:
stdenvNoCC.mkDerivation (final: {
  pname = "r2overlay";
  version = "2.0.11.0";

  src = fetchurl {
    name = final.pname;
    url = "https://catornot.net/?p=u/cat_or_not/r2overlay.git;a=blob;f=r2.zip;h=df57c87b9cbc87160a2975b96a1ca8b2b241fad7;hb=6f3c00d48546a2c9a3d92bfc63592267eb979609";
    sha256 = "sha256-ezStKoJHW0lLM/aEVP67CaSk3wODbqDVy0sbvAKbg5I=";
  };

  nativeBuildInputs = [
    ripunzip
  ];

  dontUnpack = true;

  installPhase = ''
    unpackDir="$TMPDIR/unpack"
    mkdir "$unpackDir"
    cd "$unpackDir"

    ls $src

    renamed="$TMPDIR/${baseNameOf final.src.name}.zip"
    cp "$src" "$renamed"
    ripunzip unzip-file -P ${final.pname} "$renamed" -d "$unpackDir"
    chmod -R +w "$unpackDir"

    mkdir -p "$out"
    mv $unpackDir/* "$out"
  '';

  meta = {
    description = "titanfall2 extra server files";
    homepage = "https://git.catornot.net/?p=u/cat_or_not/r2overlay.git;a=summary";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
})

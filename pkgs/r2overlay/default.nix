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
    url = "https://git.catornot.net/?p=u/cat_or_not/r2overlay.git;a=blob;f=r2.zip;h=1f00cd884fa59d6522a79af8a4aa0c74a5f2562a;hb=refs/heads/main";
    sha256 = "0psyss12zdkaczi535b3iicfrwak1pjjd1k6slzmgw94lhkm53nv";
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

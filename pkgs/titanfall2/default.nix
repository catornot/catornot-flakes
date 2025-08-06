{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (final: {
  pname = "titanfall";
  version = "2.0.11.0";

  src = fetchurl {
    url = "https://git.catornot.net/?p=u/cat_or_not/titanfall2.git;a=blob;f=titanfall2.zip;h=86dd5d3a9c9bee5013205cb31274cc82a0854d13;hb=refs/heads/main";
    sha256 = "sha256-w16y5Jhfw8MuN4r7hKZmSJsDvCBF4OW4Aw3UJJUrP0s=";
  };

  dontUnpack = true;

  installPhase = ''
    ${unzip}/bin/unzip -P ${final.pname} $src -d $out
    mv $out/titanfall2/* $out
    rmdir $out/titanfall2
  '';

  meta = {
    description = "titanfall2 server files";
    homepage = "";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
})

{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  rotationsDef,
  writeText,
}:
let
  mkPlaylistDefinition = definition: ''
    global function PlaylistRotations_Def

    void function PlaylistRotations_Def()
    {
        array<PlaylistRotationDefinition> playlists = []
        PlaylistRotationDefinition currentPlaylist
        
    ${definition}

        SetPlaylistRotations( playlists )
    }
  '';
in
stdenvNoCC.mkDerivation (final: {
  pname = "PlaylistRotations";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "catornot";
    repo = "PlaylistRotations";
    rev = "1ef1785b063fa357965c2bdc48f4ed12aa6aab6a";
    sha256 = "sha256-j7g+JqXzwDvD+TbQnE2tEfZo0COzyww5JyCrHyIAL1I=";
  };

  installPhase = ''
    unpackDir="$TMPDIR/${final.pname}"
    moveDir="$out/${final.pname}"
    mkdir -p "$unpackDir"
    mkdir -p "$moveDir"
    cp -r ${final.src}/mod "$unpackDir"
    cp -r ${final.src}/mod.json "$unpackDir"
    chmod -R a+rw "$unpackDir"

    mv "$unpackDir/mod/scripts/vscripts/_playlist_rotations_def.gnut" "$unpackDir"
    cp ${
      writeText "_playlist_rotations_def.gnut" (
        if rotationsDef != "" then
          mkPlaylistDefinition rotationsDef
        else
          throw "rotationsDef cannot be empty"
      )
    } "$unpackDir/mod/scripts/vscripts/_playlist_rotations_def.gnut"

    cp -r "$unpackDir/mod.json" "$moveDir"
    cp -r "$unpackDir/mod" "$moveDir"
  '';

  meta = {
    description = "titanfall2 server files";
    homepage = "https://git.catornot.net/?p=u/cat_or_not/titanfall2.git;a=summary";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
})

{
  lib,
  fetchurl,
  unzip,
  glibcLocalesUtf8,
}:

lib.makeOverridable (
  {
    owner,
    name,
    version,
    thunderstoreId ? "${owner}-${name}-${version}",
    baseUrl ? "gcdn.thunderstore.io",
    nativeBuildInputs ? [ ],
    postFetch ? "",
    ... # For hash agility
  }@args:
  let
    passthruAttrs = removeAttrs args [
      "owner"
      "name"
      "version"
      "thunderstoreId"
      "baseUrl"
      "nativeBuildInputs"
      "postFetch"
    ];
    url = "https://${baseUrl}/live/repository/packages/${thunderstoreId}.zip";
  in
  fetchurl (
    {
      inherit url;

      recursiveHash = true;
      downloadToTemp = true;

      nativeBuildInputs = [
        unzip
        glibcLocalesUtf8
      ]
      ++ nativeBuildInputs;

      postFetch = ''
        unpackDir="$TMPDIR/${thunderstoreId}"
        mkdir "$unpackDir"
        cd "$unpackDir"

        renamed="$TMPDIR/${thunderstoreId}.zip"
        mv "$downloadedFile" "$renamed"
        unpackFile "$renamed"
        chmod -R +w "$unpackDir"

        mkdir -p "$out"
        mv "$unpackDir" "$out"
      ''
      + postFetch;
    }
    // passthruAttrs
  )
)

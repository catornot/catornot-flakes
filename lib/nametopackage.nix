{
  lib,
  fetchurl,
  unzip,
  glibcLocalesUtf8,
}:
let
  fetchFromThunderstore = import ./fetchthunderstore.nix {
    inherit
      lib
      fetchurl
      unzip
      glibcLocalesUtf8
      ;
  };
in
{ name, ... }@args:
let
  passthruAttrs = removeAttrs args [
    "name"
  ];
in
fetchFromThunderstore (
  {
    owner = null;
    name = null;
    version = null;
    thunderstoreId = name;
  }
  // passthruAttrs
)

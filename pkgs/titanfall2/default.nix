{
  stdenv,
  lib,
  jq,
  curl,
  wget,
  pkgs,
}:
let
  fetchurlWithHeaders =
    {
      url,
      sha256,
      headers,
      ...
    }:
    pkgs.fetchurl {
      inherit url sha256;
      netrcPhase = ''
        curlOpts="$curlOpts -O ${headers}"
      '';
    };

in
stdenv.mkDerivation rec {
  pname = "titanfall";
  version = "2.0.11.0";
  tag = version + "-dedicated-mp-vpkoptim.430d3bb";
  img = "nsres/titanfall";
  reg = "ghcr.io";
  tok = "Bearer QQ==";

  # this doesn't work >:(
  # src = pkgs.fetchurl {
  #   url = "https://${reg}/v2/${img}/manifests/${tag}";
  #   sha256 = "sha256-o3kEL9oKeHq0us+zHOd8LvIkJ0fWhYpJVSIKLB+daNQ=";
  #   curlOptsList = ["-o result.part" "-H \"Accept: application/vnd.oci.image.manifest.v1+json\"" "-H \"Authorization: ${tok}\""];
  # };
  src =
    let
      manifest = fetchurlWithHeaders {
        url = "https://${reg}/v2/${img}/manifests/${tag}";
        sha256 = "sha256-o3kEL9oKeHq0us+zHOd8LvIkJ0fWhYpJVSIKLB+daNQ=";
        headers = ''-H "Accept: application/vnd.oci.image.manifest.v1+json" -H "Authorization: ${tok}"'';
      };

      mapManifest = key: keys: {
        file = builtins.trace key keys;
      };
      urls = builtins.mapAttrs mapManifest (builtins.fromJSON (builtins.readFile (builtins.trace "wow" manifest)));
      wow = builtins.trace urls "wow";
    in
    manifest + wow;

  #
  # src = ./nsfetch.sh;
  # builder = ./nsfetch.sh;

  nativeBuildInputs = [
    jq
    curl
    wget
  ];
  buildInputs = [
  ];

  unpackPhase = ''
    # bash ${src}
  '';

  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "buildPhase"
    "installPhase"
  ];
  installPhase = ''
    ls ${src}

    mv bin $out/bin
    mv vpk $out/vpk
    mv r2 $out/r2
    mv build.txt $out/build.txt
    mv gameversion.txt $out/gameversion.txt
    mv server.dll $out/server.dll
  '';

  meta = {
    description = "";
    homepage = "";
    license = lib.licenses.unfree;
    mainProgram = "";
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}

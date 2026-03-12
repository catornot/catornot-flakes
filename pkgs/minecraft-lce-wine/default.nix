{
  fetchzip,
  fetchurl,
  lib,
  copyDesktopIcons,
  copyDesktopItems,
  makeDesktopIcon,
  makeDesktopItem,
  mkWindowsAppNoCC,
  wine64Packages,
  procps,
  check-hash,
  username ? "Steve",
  graphicsDriver ? "auto",
}:
let
  assets = fetchzip {
    url = "https://github.com/smartcmd/MinecraftConsoles/releases/download/nightly/LCEWindows64.zip";
    sha256 = "sha256-CCvw5BNd2H8dowqXABPVDQ8SHE8inRGevYjeZk5WI+U=";
    stripRoot = false;
  };

  src = fetchurl {
    url = "https://github.com/smartcmd/MinecraftConsoles/releases/download/nightly/Minecraft.Client.exe";
    sha256 = "sha256-wTeEG2TMMuuBc6QHHhcsIK2p3ytxLd2qPkuPqd0ECP0=";
  };
in
mkWindowsAppNoCC rec {
  # Use mkWindowsApp just like mkDerivation.
  wine = wine64Packages.base;
  enableVulkan = true;
  inhibitIdle = true;
  enableHug = true;
  enableMonoBootPrompt = false;
  rendererOverride = "dxvk-vulkan";

  pname = "MinecraftConsoles";
  version = "0.0.0";

  inherit src graphicsDriver;

  dontUnpack = true;
  wineArch = "win64";

  nativeBuildInputs = [
    copyDesktopItems
    copyDesktopIcons
  ];

  fileMap = {
    "$HOME/.local/share/${pname}" = "drive_c/Windows64/GameHDD";
  };

  # This is executed to install the Windows application.
  # mkWindowsApp will set up a Wine Bottle and then run this script. Anything written to the Wine Bottle
  # will be stored in the application layer.
  # wine, winetricks, cabextract, $WINEPREFIX, $WINEARCH, and $WINEDLLOVERRIDES are available and set up.
  winAppInstall = /* bash */ ''
    # ${lib.getExe check-hash} "$WINEPREFIX/drive_c" "${assets}" minecraftHash
    for f in "${assets}"/*; do
      ln -sf "$f" "$WINEPREFIX/drive_c/"
    done
    rm "$WINEPREFIX/drive_c/Windows64" &2> /dev/null
    rm "$WINEPREFIX/drive_c/Minecraft.Client.exe" &2> /dev/null

    mkdir -p "$WINEPREFIX/drive_c/Windows64"
    mkdir -p "$WINEPREFIX/drive_c/Windows64/GameHDD"

    cp ${src} "$WINEPREFIX/drive_c/Minecraft.Client.exe"
  '';

  # This is executed after winAppInstall (if needed)  to run the Windows application.
  # mkWindowsApp will set up a Wine Bottle and then run this script.
  # By this time both read-only layers would have been created, so anything written to the Wine Bottle
  # will be discarded once the script terminates.
  # wine, winetricks, cabextract, $WINEPREFIX, $WINEARCH, and $WINEDLLOVERRIDES are available and set up.
  winAppRun = /* bash */ ''
    NAME="${username}"
    ${
      (
        if username == "Steve" then
          ''
            if [ -n "$USER" ]; then
              NAME="$USER"
            fi
          ''
        else
          ""
      )
    }

    RUNNING="$(${lib.getExe' procps "pgrep"} -fc "Minecraft" || true)"

    if [ "$RUNNING" -gt 0 ]; then
      NAME="$NAME($RUNNING)"
    fi

    echo "Number of instances: $RUNNING"
    echo "Username: $NAME"

    $WINE start /unix "$WINEPREFIX/drive_c/Minecraft.Client.exe" -name "$NAME" -fullscreen "$ARGS"
  '';

  installPhase = ''
    runHook preInstall

    ln -s $out/bin/.launcher $out/bin/${pname}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      desktopName = "Minecraft Legacy Console Edition";
      categories = [
        "Game"
        "X-Sandbox"
      ];
    })
  ];

  desktopIcon = makeDesktopIcon {
    name = pname;
    src = "${assets}/Common/res/pack.png";
    icoIndex = 0;
  };

  meta = with lib; {
    description = "Minecraft Legacy Console Edition";
    homepage = "https://github.com/smartcmd/MinecraftConsoles";
    license = licenses.unfree;
    maintainers = with maintainers; [ cat_or_not ];
    platforms = [
      "x86_64-linux"
      "i386-linux"
    ];
  };
}

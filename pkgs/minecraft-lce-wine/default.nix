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
  username ? "Steve",
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

  pname = "MinecraftConsoles";
  version = "0.0.0";

  inherit src;

  dontUnpack = true;
  wineArch = "win64";

  nativeBuildInputs = [
    copyDesktopItems
    copyDesktopIcons
  ];

  # This is executed to install the Windows application.
  # mkWindowsApp will set up a Wine Bottle and then run this script. Anything written to the Wine Bottle
  # will be stored in the application layer.
  # wine, winetricks, cabextract, $WINEPREFIX, $WINEARCH, and $WINEDLLOVERRIDES are available and set up.
  winAppInstall = ''
    cp -r ${assets}/* "$WINEPREFIX/drive_c"
    rm "$WINEPREFIX/drive_c/Minecraft.Client.exe" &2> /dev/null

    cp ${src} "$WINEPREFIX/drive_c/Minecraft.Client.exe"

    export WINEDLLOVERRIDES="dxgi=n,b;d3d11=n,b"
    winetricks -q vcrun2019 dotnet48 dxvk
  '';

  # This is executed after winAppInstall (if needed)  to run the Windows application.
  # mkWindowsApp will set up a Wine Bottle and then run this script.
  # By this time both read-only layers would have been created, so anything written to the Wine Bottle
  # will be discarded once the script terminates.
  # wine, winetricks, cabextract, $WINEPREFIX, $WINEARCH, and $WINEDLLOVERRIDES are available and set up.
  winAppRun = ''
    # bash
           export WINEDLLOVERRIDES="dxgi=n,b;d3d11=n,b"

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

{
  fetchzip,
  lib,
  copyDesktopIcons,
  copyDesktopItems,
  makeDesktopIcon,
  makeDesktopItem,
  mkWindowsAppNoCC,
  wineWow64Packages,
  zenity,
  graphicsDriver ? "auto",
  gameDir ? "$HOME/.local/share/Steam/steamapps/common/Titanfall2",
  maxima-windows,
}:
let
  wineGameDir = "drive_c/Titanfall2";
  exePath = "$WINEPREFIX/${wineGameDir}/NorthstarLauncher.exe";
in
mkWindowsAppNoCC rec {
  # Use mkWindowsApp just like mkDerivation.
  wine = wineWow64Packages.stable;
  enableVulkan = true;
  inhibitIdle = true;
  enableHug = true;
  enableMonoBootPrompt = false;
  rendererOverride = "dxvk-vulkan";
  dxvkOptions = {
    enableDXGI = true;
    enableD3D10 = true;
  };

  pname = "Titanfall2";
  version = "0.0.0";

  inherit graphicsDriver;
  src = ./.;

  dontUnpack = true;
  wineArch = "win64";

  nativeBuildInputs = [
    copyDesktopItems
    copyDesktopIcons
  ];

  fileMap = {
    ${gameDir} = wineGameDir;
    # "$HOME/.local/share/${pname}" = "drive_c/users/$USER/AppData/LocalLow/...";
  };

  # This is executed to install the Windows application.
  # mkWindowsApp will set up a Wine Bottle and then run this script. Anything written to the Wine Bottle
  # will be stored in the application layer.
  # wine, winetricks, cabextract, $WINEPREFIX, $WINEARCH, and $WINEDLLOVERRIDES are available and set up.
  winAppInstall = /* bash */ ''
    cp ${maxima-windows}/bin/* "$WINEPREFIX/drive_c" 

    mkdir -p "$WINEPREFIX/${wineGameDir}"
  '';

  # This is executed after winAppInstall (if needed)  to run the Windows application.
  # mkWindowsApp will set up a Wine Bottle and then run this script.
  # By this time both read-only layers would have been created, so anything written to the Wine Bottle
  # will be discarded once the script terminates.
  # wine, winetricks, cabextract, $WINEPREFIX, $WINEARCH, and $WINEDLLOVERRIDES are available and set up.
  winAppRun = /* bash */ ''
    if [ -f "${exePath}" ]; then
      # $WINE regedit ${./link2ea.reg}
      $WINE start /unix "$WINEPREFIX/drive_c/maxima-bootstrap.exe";
      $WINE start /unix "${exePath}";
    else
      ${zenity}/bin/zenity --error --text "Could not find the Titanfall2 installation at: ${gameDir}"
    fi
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
      desktopName = "Titanfall 2 wine prefix setup";
      categories = [
        "Game"
        ""
      ];
    })
  ];

  # desktopIcon = makeDesktopIcon {
  #   name = pname;
  #   src = "${src}/Common/res/pack.png";
  #   icoIndex = 0;
  # };

  meta = with lib; {
    description = "Titanfall 2 wine";
    homepage = "";
    license = licenses.unfree;
    maintainers = with maintainers; [ cat_or_not ];
    platforms = [
      "x86_64-linux"
      "i386-linux"
    ];
  };
}

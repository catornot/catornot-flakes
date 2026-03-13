{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
  writeText,
  pkgsCross,
  llvmPackages,
  perl,
  pkg-config,
  git,
}:
let

  cross = pkgsCross.x86_64-windows;

  toolchainHelper = rec {
    base = cross.windows.sdk;
    arch = "x64";
    MSVC_INCLUDE = "${base}/crt/include";
    MSVC_LIB = "${base}/crt/lib";
    WINSDK_INCLUDE = "${base}/sdk/Include";
    WINSDK_LIB = "${base}/sdk/Lib";
    CMAKE_CURRENT_SOURCE_DIR = "/build/source";
    mkArgs = args: builtins.concatStringsSep " " args;
    linker = mkArgs [
      "/manifest:no"
      "-libpath:${MSVC_LIB}"
      "-libpath:${WINSDK_LIB}/ucrt/${arch}"
      "-libpath:${WINSDK_LIB}/um/${arch}"
      "-libpath:${WINSDK_LIB}/${arch}"
      "-libpath:${MSVC_LIB}/${arch}"
    ];
    compiler = mkArgs [
      "/vctoolsdir ${cross.windows.sdk}/crt"
      "/winsdkdir ${cross.windows.sdk}/sdk"
      # tbh I am not sure what is exactly needed here since I just copied a execiting toolchain file from somewhere
      # if it causes problems remove it but since it doesn't cause I don't see any reason in removing this
      # thougths?
      "/EHs"
      "-D_CRT_SECURE_NO_WARNINGS"
      "--target=x86_64-windows-msvc"
      "-fms-compatibility-version=19.11"
      "-imsvc ${MSVC_INCLUDE}"
      "-imsvc ${WINSDK_INCLUDE}/ucrt"
      "-imsvc ${WINSDK_INCLUDE}/shared"
      "-imsvc ${WINSDK_INCLUDE}/um"
      "-imsvc ${WINSDK_INCLUDE}/winrt"
    ];
  };

  toolchainFile =
    let
      inherit (toolchainHelper)
        linker
        compiler
        WINSDK_INCLUDE
        WINSDK_LIB
        MSVC_INCLUDE
        MSVC_LIB
        CMAKE_CURRENT_SOURCE_DIR
        ;

    in
    writeText "WindowsToolchain.cmake" ''
      set(CMAKE_SYSTEM_NAME Windows)
      set(CMAKE_SYSTEM_VERSION 10.0)
      set(CMAKE_SYSTEM_PROCESSOR x86_64)
      set(CMAKE_SIZEOF_VOID_P 8)

      set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

      set(CMAKE_C_COMPILER clang-cl)
      set(CMAKE_CXX_COMPILER clang-cl)
      set(CMAKE_AR llvm-lib)
      set(CMAKE_LINKER lld-link)
      set(CMAKE_RC_COMPILER llvm-rc)

      set(CMAKE_C_COMPILER_TARGET x86_64-pc-windows-msvc)
      set(CMAKE_CXX_COMPILER_TARGET x86_64-pc-windows-msvc)

      set(CMAKE_C_FLAGS_INIT "${compiler}")
      set(CMAKE_CXX_FLAGS_INIT "${compiler}")

      set(CMAKE_EXE_LINKER_FLAGS_INIT "${linker}")
      set(CMAKE_SHARED_LINKER_FLAGS_INIT "${linker}")
      set(CMAKE_MODULE_LINKER_FLAGS_INIT "${linker}")

      set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreaded)

      include_directories(
        ${MSVC_INCLUDE}
        ${WINSDK_INCLUDE}/ucrt
        ${WINSDK_INCLUDE}/shared
        ${WINSDK_INCLUDE}/um
        ${WINSDK_INCLUDE}/winrt
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.Client
        ${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.Client/Common
        ${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.Client/Windows64/4JLibs/inc
        ${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.World
        ${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.World/x64headers
      )

      set(CMAKE_VERBOSE_MAKEFILE ON)
    '';

  mkBuildDir = /* bash */ "cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=${toolchainFile} -DCMAKE_POLICY_VERSION_MINIMUM=3.5";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "MinecraftConsoles";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "smartcmd";
    repo = "MinecraftConsoles";
    rev = "714462b130f98558744a06f8dbc4fa6f2f2b3c62";
    hash = "sha256-bvinKuqbj7dCsdVWon1t5LOhxkPvYWeeeEpq/EQztRc=";
  };

  nativeBuildInputs = [
    cross.buildPackages.cmake
    cross.buildPackages.ninja
    cross.buildPackages.msitools
    llvmPackages.clang-unwrapped
    llvmPackages.bintools-unwrapped
    perl
    pkg-config
    git
  ];

  buildInputs = [
    cross.windows.sdk
  ];

  dontUseCmakeConfigure = true;
  phases = [
    "unpackPhase"
    "patchPhase"
    "postPatchPhase"
    "buildPhase"
    "installPhase"
  ];

  postPatchPhase = ''
    ${./patch-includes.sh}
  '';

  buildPhase = ''
    mkdir -p build

    ${mkBuildDir}

    cmake --build build --config Debug --target MinecraftClient
  '';

  installPhase = ''
    mkdir -p $out
    cp -r  build/* $out
  '';

  meta = {
    description = "Northstar launcher";
    homepage = "https://northstar.tf/";
    license = lib.licenses.mit;
    mainProgram = "NorthstarLauncher";
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
})

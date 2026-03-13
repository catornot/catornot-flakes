#!/bin/sh

shopt -s globstar

find . -type f \( -name "*.h" -o -name "*.hpp" -o -name "*.cpp" \) -exec \
  sed -i -E '/#include[[:space:]]*"/s|\\|/|g' {} +

# find /build/source -type f \( -name '*.h' -o -name '*.hpp' -o -name '*.cpp' -o -name '*.c' \) \
#   -exec sed -i 's@#include\s*"\.\./Minecraft\.Client/\(.*\)"@#include "\1"@g' {} +

sed -i 's|#include\s*"\.\./Minecraft\.Client/\(.*\)"|#include "build/source/Minecraft.Client/\1"|g' **/*.cpp **/*.h

sed -i '/target_include_directories(MinecraftWorld PRIVATE/,/)/c\
target_include_directories(MinecraftWorld PRIVATE\
  "${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.Client"\
  "${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.Client/Windows64/Iggy/include"\
  "${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.Client/Xbox/Sentient/Include"\
  "${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.World/x64headers"\
  "${CMAKE_CURRENT_SOURCE_DIR}/include/"\
)' CMakeLists.txt

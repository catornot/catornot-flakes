#!/bin/sh

shopt -s globstar

find . -type f \( -name "*.h" -o -name "*.hpp" -o -name "*.cpp" \) -exec \
  sed -i -E '/#include[[:space:]]*"/s|\\|/|g' {} +

# find /build/source -type f \( -name '*.h' -o -name '*.hpp' -o -name '*.cpp' -o -name '*.c' \) \
#   -exec sed -i 's@#include\s*"\.\./Minecraft\.Client/\(.*\)"@#include "\1"@g' {} +

sed -i 's|#include\s*"\.\./Minecraft\.Client/\(.*\)"|#include "\1"|g' **/*.cpp **/*.h
sed -i 's|#include\s*"build/source/Minecraft\.Client/\(.*\)"|#include "\1"|g' **/*.cpp **/*.h
# normalize Common includes so they resolve from Minecraft.Client root
sed -i 's|#include\s*"Common/\(.*\)"|#include "Minecraft.Client/Common/\1"|g' **/*.cpp **/*.h
# case-sensitive filesystem fix for Windows-style filename
sed -i 's|Minecraft.Client/Common/App_defines.h|Minecraft.Client/Common/App_Defines.h|g' **/*.cpp **/*.h
sed -i 's/\bGlowstonetile\b/GlowstoneTile/g' **/*.cpp **/*.h
sed -i 's/\SnowBallItem\b/SnowballItem/g' **/*.cpp **/*.h
sed -i 's/\b"biome.h"\b/"Biome.h"/g' **/*.cpp **/*.h

sed -i '/target_include_directories(MinecraftWorld PRIVATE/,/)/c\
target_include_directories(MinecraftWorld PRIVATE\
  "${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.Client"\
  "${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.Client/Windows64/Iggy/include"\
  "${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.Client/Xbox/Sentient/Include"\
  "${CMAKE_CURRENT_SOURCE_DIR}/Minecraft.World/x64headers"\
  "${CMAKE_CURRENT_SOURCE_DIR}/include/"\
)' CMakeLists.txt

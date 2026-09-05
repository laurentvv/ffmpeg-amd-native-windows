#!/bin/bash
# Generates the renamed import libraries referenced by the override .pc files.
# Run from anywhere; copies from the local MSYS2 UCRT64 toolchain.
FFROOT="${FFROOT:-/c/ffmpeg}"
LIBS="$FFROOT/msys64/ucrt64/lib"
DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$LIBS/libvulkan-1.dll.a" "$DIR/libvulkan_1_sys.a"   # links against system vulkan-1.dll (GPU driver)
cp "$LIBS/libhwy.dll.a"      "$DIR/libhwy_dll.a"        # links against bundled libhwy.dll (JPEG XL)
echo "Overrides generated in $DIR"

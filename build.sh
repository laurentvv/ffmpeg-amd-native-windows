#!/bin/bash
# ============================================================
#  build.sh — Full-featured personal build
#
#  Machine-optimized (run ON the target machine):
#    --cpu=native, -O3, LTO, fully static monolithic binaries
#    AMD GPU: AMF encoders, Vulkan, D3D12VA/D3D11VA/DXVA2, libplacebo
#
#  Includes libfdk-aac => "nonfree" (GPL-incompatible):
#  keep the produced binaries for yourself, do NOT redistribute.
#  For a redistributable build, use build_gpl.sh instead.
#
#  Requires setup.sh to have been run once (isolated MSYS2 in
#  $FFROOT/msys64, sources in $FFROOT/src, overrides ready).
#
#  Usage (UCRT64 shell):
#    FFROOT=/c/ffmpeg bash build.sh
#    cd $FFROOT/build_work && make -j$(nproc) && make install
# ============================================================
set -e
FFROOT="${FFROOT:-/c/ffmpeg}"
SRC=$FFROOT/src
BUILD=$FFROOT/build_work
PREFIX=$FFROOT/dist

# Static-link overrides (see pc-override/README.md)
export PKG_CONFIG_PATH=$FFROOT/pc-override:$FFROOT/msys64/ucrt64/lib/pkgconfig

mkdir -p "$BUILD" "$PREFIX"
cd "$BUILD"

"$SRC/configure" \
  --prefix="$PREFIX" \
  --pkg-config-flags=--static \
  --extra-cflags="-DLIBTWOLAME_STATIC" \
  --extra-ldflags="-static -static-libgcc -static-libstdc++ -flto=24" \
  --extra-libs="-liconv -lstdc++ -lharfbuzz -lfreetype -lgomp" \
  --cpu=native \
  --enable-lto \
  --enable-gpl \
  --enable-version3 \
  --enable-nonfree \
  --disable-shared \
  --enable-static \
  --disable-debug \
  --disable-w32threads \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libsvtav1 \
  --enable-libaom \
  --enable-libdav1d \
  --enable-libvpx \
  --enable-libwebp \
  --enable-libjxl \
  --enable-libopenjpeg \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libtheora \
  --enable-libspeex \
  --enable-libtwolame \
  --enable-libfdk-aac \
  --enable-libbs2b \
  --enable-libsoxr \
  --enable-libmysofa \
  --enable-libmodplug \
  --enable-libopenmpt \
  --enable-libgme \
  --enable-libass \
  --enable-libfreetype \
  --enable-libfribidi \
  --enable-libharfbuzz \
  --enable-libfontconfig \
  --enable-libzimg \
  --enable-libxml2 \
  --enable-libsrt \
  --enable-librist \
  --enable-libplacebo \
  --enable-libvmaf \
  --enable-ffplay
# AMF, Vulkan, D3D11VA, DXVA2, D3D12VA, MediaFoundation, SDL2, schannel TLS:
# auto-detected (headers installed by setup.sh)

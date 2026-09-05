#!/bin/bash
# ============================================================
#  build_gpl.sh — Redistributable GPL build
#
#  Identical optimizations to build.sh (--cpu=native, -O3, LTO,
#  fully static) but WITHOUT libfdk-aac, so the produced
#  binaries are GPL and may be redistributed/published.
#  This is the variant used for the GitHub releases.
#
#  Usage (UCRT64 shell):
#    FFROOT=/c/ffmpeg bash build_gpl.sh
#    cd $FFROOT/build_work_gpl && make -j$(nproc) && make install
# ============================================================
set -e
FFROOT="${FFROOT:-/c/ffmpeg}"
SRC=$FFROOT/src
BUILD=$FFROOT/build_work_gpl
PREFIX=$FFROOT/dist-gpl

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

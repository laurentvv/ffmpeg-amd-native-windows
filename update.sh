#!/bin/bash
# ============================================================
#  update.sh — One-command maintenance
#
#  1. Detects the latest FFmpeg release from ffmpeg.org
#  2. Exits if the current build is already up to date
#     (--force rebuilds anyway, --dry-run simulates)
#  3. Refreshes MSYS2 + every library (rolling release)
#  4. Downloads sources, backs up dist/ -> dist.bak/
#  5. Clean rebuild (build.sh = nonfree variant) + install
#  6. Sanity check: version, AMF encoders, GPU encode test
#
#  Usage (UCRT64 shell):
#    FFROOT=/c/ffmpeg bash update.sh [--force|--dry-run]
# ============================================================
set -e
FFROOT="${FFROOT:-/c/ffmpeg}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$FFROOT"

FORCE=0; DRY=0
for a in "$@"; do case "$a" in
  --force) FORCE=1 ;; --dry-run) DRY=1 ;;
esac; done
SH="MSYSTEM=UCRT64 $FFROOT/msys64/usr/bin/bash.exe -lc"

# --- 1. Latest upstream release ---
LATEST=$(curl -s https://ffmpeg.org/releases/ | grep -oE 'ffmpeg-[0-9]+\.[0-9]+(\.[0-9]+)?\.tar\.xz' | sort -uV | tail -1 | sed 's/ffmpeg-//; s/\.tar\.xz//')
[ -z "$LATEST" ] && { echo "ERROR: cannot reach ffmpeg.org"; exit 1; }
echo "Latest FFmpeg release : $LATEST"

# --- 2. Compare with current build ---
CURRENT="none"
[ -x dist/bin/ffmpeg.exe ] && CURRENT=$(./dist/bin/ffmpeg.exe -version 2>/dev/null | head -1 | grep -oE "version [0-9.]+" | cut -d' ' -f2)
echo "Current build         : $CURRENT"
if [ "$LATEST" = "$CURRENT" ] && [ $FORCE -eq 0 ]; then
  echo "Already up to date — nothing to do (use --force to rebuild anyway)."
  exit 0
fi
if [ $DRY -eq 1 ]; then echo "[dry-run] Would rebuild $LATEST here."; exit 0; fi

# --- 3. Rolling refresh of toolchain + libraries ---
echo "== Refreshing MSYS2 & libraries =="
$SH 'pacman -Syu --noconfirm' || true
$SH 'pacman -Syu --noconfirm'
$SH 'pacman -S --needed --noconfirm \
  make nasm yasm diffutils \
  mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-pkgconf \
  mingw-w64-ucrt-x86_64-x264 mingw-w64-ucrt-x86_64-x265 \
  mingw-w64-ucrt-x86_64-svt-av1 mingw-w64-ucrt-x86_64-aom mingw-w64-ucrt-x86_64-dav1d \
  mingw-w64-ucrt-x86_64-libvpx mingw-w64-ucrt-x86_64-lame mingw-w64-ucrt-x86_64-opus \
  mingw-w64-ucrt-x86_64-libvorbis mingw-w64-ucrt-x86_64-fdk-aac \
  mingw-w64-ucrt-x86_64-libass mingw-w64-ucrt-x86_64-freetype mingw-w64-ucrt-x86_64-fribidi \
  mingw-w64-ucrt-x86_64-harfbuzz mingw-w64-ucrt-x86_64-fontconfig \
  mingw-w64-ucrt-x86_64-libplacebo mingw-w64-ucrt-x86_64-libdovi mingw-w64-ucrt-x86_64-libjxl \
  mingw-w64-ucrt-x86_64-zimg mingw-w64-ucrt-x86_64-srt mingw-w64-ucrt-x86_64-librist \
  mingw-w64-ucrt-x86_64-vmaf mingw-w64-ucrt-x86_64-openjpeg2 mingw-w64-ucrt-x86_64-libwebp \
  mingw-w64-ucrt-x86_64-libxml2 mingw-w64-ucrt-x86_64-amf-headers \
  mingw-w64-ucrt-x86_64-vulkan-headers mingw-w64-ucrt-x86_64-vulkan-loader \
  mingw-w64-ucrt-x86_64-spirv-cross mingw-w64-ucrt-x86_64-glslang mingw-w64-ucrt-x86_64-shaderc \
  mingw-w64-ucrt-x86_64-mbedtls mingw-w64-ucrt-x86_64-libiconv \
  mingw-w64-ucrt-x86_64-libtheora mingw-w64-ucrt-x86_64-speex mingw-w64-ucrt-x86_64-twolame \
  mingw-w64-ucrt-x86_64-libbs2b mingw-w64-ucrt-x86_64-libsoxr mingw-w64-ucrt-x86_64-libmysofa \
  mingw-w64-ucrt-x86_64-libmodplug mingw-w64-ucrt-x86_64-libopenmpt mingw-w64-ucrt-x86_64-libgme \
  mingw-w64-ucrt-x86_64-SDL2 mingw-w64-ucrt-x86_64-zlib mingw-w64-ucrt-x86_64-bzip2 \
  mingw-w64-ucrt-x86_64-xz mingw-w64-ucrt-x86_64-zstd'
bash "$FFROOT/pc-override/generate.sh"   # refresh renamed import libs

# --- 4. Sources ---
echo "== Fetching sources $LATEST =="
mkdir -p downloads
curl -sL -o "downloads/ffmpeg-$LATEST.tar.xz" "https://ffmpeg.org/releases/ffmpeg-$LATEST.tar.xz"
rm -rf src build_work
tar -xf "downloads/ffmpeg-$LATEST.tar.xz" && mv "ffmpeg-$LATEST" src

# --- 5. Backup + clean rebuild ---
echo "== Building =="
rm -rf dist.bak
[ -d dist ] && mv dist dist.bak
bash "$SCRIPT_DIR/build.sh"
cd build_work && make -j24 && make install
cp /ucrt64/bin/libhwy.dll "$FFROOT/dist/bin/"

# --- 6. Sanity check ---
echo "== Sanity check =="
"$FFROOT/dist/bin/ffmpeg.exe" -version | head -1
echo -n "AMF encoders: "
"$FFROOT/dist/bin/ffmpeg.exe" -hide_banner -encoders 2>/dev/null | grep -c "_amf"
"$FFROOT/dist/bin/ffmpeg.exe" -hide_banner -y -f lavfi -i testsrc2=duration=2:size=640x360:rate=30 \
  -c:v h264_amf -quality speed /tmp/update-check.mp4 2>/dev/null \
  && echo "GPU AMF encode test: OK" || echo "WARNING: GPU AMF encode test failed"
echo "Done. Previous build kept in dist.bak (safe to delete)."

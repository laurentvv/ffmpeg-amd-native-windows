#!/bin/bash
# ============================================================
#  setup.sh — One-shot environment setup for fully-static,
#  machine-optimized FFmpeg builds on Windows.
#
#  Downloads a portable MSYS2 (no system install, nothing in the
#  registry), installs the toolchain + libraries, prepares the
#  pkg-config overrides and fetches the latest FFmpeg release.
#
#  Everything lives under FFROOT (default: the parent directory
#  of this repository checkout).
#
#  Run from an MSYS2/UCRT64-capable shell (Git Bash works):
#    bash setup.sh
# ============================================================
set -e
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
FFROOT="${FFROOT:-$(dirname "$REPO_DIR")}"
MSYS="$FFROOT/msys64"
SH="MSYSTEM=UCRT64 $MSYS/usr/bin/bash.exe -lc"

mkdir -p "$FFROOT"
cd "$FFROOT"
echo "FFROOT = $FFROOT"

# --- 1. Portable MSYS2 -------------------------------------------------
if [ ! -x "$MSYS/usr/bin/pacman.exe" ]; then
  echo "== Downloading portable MSYS2 =="
  mkdir -p downloads && cd downloads
  BASE=$(curl -s https://repo.msys2.org/distrib/x86_64/ | grep -oE 'msys2-base-x86_64-[0-9]+\.tar\.xz' | sort -uV | tail -1)
  curl -sL -o msys2-base.tar.xz "https://repo.msys2.org/distrib/x86_64/$BASE"
  cd "$FFROOT" && tar -xf downloads/msys2-base.tar.xz
  # Prefer the official mirror (third-party mirrors rate-limit)
  sed -i '1i Server = https://repo.msys2.org/mingw/$repo/' "$MSYS/etc/pacman.d/mirrorlist.mingw"
  sed -i '1i Server = https://repo.msys2.org/msys/$arch/'  "$MSYS/etc/pacman.d/mirrorlist.msys"
fi

# --- 2. Update + toolchain/libs ----------------------------------------
echo "== pacman update (two passes: runtime may restart) =="
$SH 'pacman -Syu --noconfirm' || true
$SH 'pacman -Syu --noconfirm'

echo "== Installing toolchain + libraries =="
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

# --- 3. pkg-config overrides -------------------------------------------
echo "== pkg-config overrides =="
rm -rf "$FFROOT/pc-override"
cp -r "$REPO_DIR/pc-override" "$FFROOT/pc-override"
bash "$FFROOT/pc-override/generate.sh"

# --- 4. Latest FFmpeg sources ------------------------------------------
echo "== Fetching latest FFmpeg release =="
LATEST=$(curl -s https://ffmpeg.org/releases/ | grep -oE 'ffmpeg-[0-9]+\.[0-9]+(\.[0-9]+)?\.tar\.xz' | sort -uV | tail -1)
mkdir -p "$FFROOT/downloads"
[ -f "downloads/$LATEST" ] || curl -sL -o "downloads/$LATEST" "https://ffmpeg.org/releases/$LATEST"
rm -rf "$FFROOT/src" && tar -xf "downloads/$LATEST" -C "$FFROOT" \
  && mv "$FFROOT/ffmpeg-${LATEST#ffmpeg-}" "$FFROOT/src" 2>/dev/null || \
  mv "$FFROOT/${LATEST%.tar.xz}" "$FFROOT/src"

cat <<DONE

Setup complete. Next steps:

  # Full build (personal, includes libfdk-aac => nonfree, do NOT redistribute)
  MSYSTEM=UCRT64 $MSYS/usr/bin/bash.exe -lc 'FFROOT=$FFROOT bash $REPO_DIR/build.sh && cd $FFROOT/build_work && make -j24 && make install'

  # GPL build (redistributable, no fdk-aac) — what the GitHub releases use
  MSYSTEM=UCRT64 $MSYS/usr/bin/bash.exe -lc 'FFROOT=$FFROOT bash $REPO_DIR/build_gpl.sh && cd $FFROOT/build_work_gpl && make -j24 && make install'

  cp $MSYS/ucrt64/bin/libhwy.dll $FFROOT/dist*/bin/   # only external DLL (JPEG XL)
DONE

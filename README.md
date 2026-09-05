# FFmpeg AMD-Native for Windows

**Machine-optimized, fully-static FFmpeg builds for Windows targeting AMD GPUs and modern Intel CPUs — with a complete, reproducible, isolated build system.**

![FFmpeg](https://img.shields.io/badge/FFmpeg-9.0.1-007808?logo=ffmpeg&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-0078D6?logo=windows11)
![GPU](https://img.shields.io/badge/GPU-AMD%20AMF%20%7C%20Vulkan%20%7C%20D3D12-76B900?logo=amd)
![License](https://img.shields.io/badge/binaries-GPL--3.0-blue)
![Toolchain](https://img.shields.io/badge/toolchain-GCC%2016%20%2B%20MSYS2%20UCRT64-orange)

Built and benchmarked on a **Ryzen-class rig: i7-13700KF + RX 6950 XT + 32 GB RAM**. Every binary is compiled *on and for* the target machine: native CPU codegen, GPU encoder/decoder stack, and a near-monolithic executable with zero runtime installer dependencies.

---

## What exactly does this build add?

### 1. Native CPU optimization (i7-13700KF / Raptor Lake)
| Flag | Effect |
|---|---|
| `--cpu=native` → `-march=native` | AVX2, FMA, BMI2, AVX-VNNI codegen across **all** C code — not just hand-written asm |
| `-O3` + `--enable-lto` + `-flto=24` | Interprocedural optimization, parallel LTO link across 24 threads |
| `make -j24` | Full 16C/24T utilization |

Benchmarked with **hyperfine** (2 warmups + 8 runs, min/mean/max/σ) on real-world sources — a 4K H.264 production master and an AI-generated 1080p60 film — against gyan.dev full 9.0.1 and BtbN win64-gpl master (same machine, idle):

| Workload | **This build** | gyan full | BtbN gpl | Winner |
|---|---|---|---|---|
| Decode 4K H.264 → null (CPU) | 1.086 s ± 0.006 | 1.104 s ± 0.003 | **1.080 s ± 0.003** | tie ±2% |
| Transcode 4K→1080p `h264_amf` (GPU) | **2.157 s ± 0.011** | 2.178 s ± 0.015 | 2.162 s ± 0.011 | **this build** (13.9× realtime) |
| Transcode 4K→1080p `libx264 -fast` | **2.998 s** ± 0.016 | 3.002 s ± 0.007 | 3.000 s ± 0.004 | tie ±0.1% |
| Encode AI film `libsvtav1 -p6` | **2.713 s ± 0.015** | 2.874 s ± 0.069 | 2.975 s ± 0.034 | **this build +6% / +10%** |
| Encode AI film `libx265 -fast` | 2.337 s ± 0.010 | 2.339 s ± 0.011 | **2.334 s ± 0.010** | tie ±0.2% |
| Decode AV1 1080p `dav1d` (CPU) | **0.772 s ± 0.003** | 0.798 s ± 0.017 | 0.789 s ± 0.008 | **this build** (newer dav1d 1.5.4) |
| Decode AV1 1080p `d3d12va` (GPU) | **0.467 s ± 0.004** | — | — | **RDNA2 GPU: 1.66–1.71× faster than any CPU** |

**How to read this honestly:**
- Where library versions are identical (x264, x265, H.264 decode): statistical ties. The hot paths are hand-written assembly with runtime CPU dispatch — `--cpu=native` can't add much there.
- Where this build's *newer library* does the work (SVT-AV1 4.2 vs older): **+6–10% real speedup**. This is the rolling-release advantage: public builds freeze their library set at their build date.
- The GPU results are hardware facts about the reference rig: RDNA2 decodes AV1 in hardware 1.67× faster than dav1d, and the full 4K→AMF pipeline runs at 13.9× realtime.

### 2. Complete AMD GPU stack
- **AMF hardware encoders**: `h264_amf` (measured 257 fps @1080p), `hevc_amf` (10× realtime), `av1_amf` (RX 7000+ only — RDNA2 silicon lacks an AV1 encoder)
- **Hardware decode**: D3D12VA, D3D11VA, DXVA2, Vulkan
- **GPU processing**: Vulkan compute filters + **libplacebo 7.360** (statically linked — high-quality tonemapping, scaling, debanding, dithering)

### 3. Windows-native choices
- **schannel TLS** instead of gnutls/openssl (faster, no extra crypto stack)
- **Near-monolithic binaries**: ~123 MB `ffmpeg.exe`; the only non-system imports are `vulkan-1.dll` (your GPU driver) and `libhwy.dll` (bundled, for JPEG XL)
- pthreads via winpthreads (statically linked)

### 4. Fresher library stack (rolling releases)
Compiled the day you build, e.g. in this reference build: GCC 16.2, x265 4.3, SVT-AV1 4.2, dav1d 1.5.4, libplacebo 7.360.1, libjxl 0.12, libvpx 1.16. Public builds freeze their library set at *their* build date.

### 5. Two variants
| Variant | Script | AAC | License | Purpose |
|---|---|---|---|---|
| **Full** | `build.sh` | `libfdk-aac` (best AAC) + native | **nonfree — keep private** | Daily driver |
| **GPL** | `build_gpl.sh` | native AAC only | GPL-3.0, redistributable | GitHub releases |

### Deliberately excluded (and why)
- `nvenc / nvenc / cuvid` — NVIDIA-only hardware paths (this is an AMD rig)
- `libvpl / QSV` — the i7-**KF** has no integrated GPU
- Legacy telephony codecs (AMR, GSM, iLBC, codec2), Xvid, AVS2/AVS3, VVC encoders, whisper — dead or niche formats; the native **VVC decoder** *is* included
- `libaribcaption` — MSYS2 ships a version too old for static linking

## Codec / feature coverage

**220 encoders · 525 decoders · all 524 filters** — including x264, x265, SVT-AV1 (the practical AV1 choice at 194 fps @1080p on this CPU), aom, dav1d, libvpx, JPEG XL, OpenJPEG, WebP, libass/fontconfig/harfbuzz subtitles, zimg/zscale, libvmaf, SRT/RIST, Opus/MP3/Vorbis/Theora/Speex/twoolame, soxr resampling, mysofa HRTF, modplug/openmpt/GME chiptunes.

## Quick start

### Use the prebuilt binaries
Grab a **GPL build** from [Releases](../../releases): unzip, add `bin/` to your PATH, done. Built with the exact same scripts as this repo.

```bash
# GPU encode — H.264 (fast, streaming)
ffmpeg -i in.mkv -c:v h264_amf -quality quality -rc cqp -qp_i 22 -qp_p 24 -c:a copy out.mp4

# GPU encode — HEVC
ffmpeg -i in.mkv -c:v hevc_amf -quality quality -b:v 10M -c:a copy out.mp4

# AV1 on the CPU (RDNA2 has no AV1 encoder — SVT-AV1 is excellent here)
ffmpeg -i in.mkv -c:v libsvtav1 -preset 6 -crf 27 -c:a libopus -b:a 160k out.mkv

# Archive-grade H.265 (full variant only: FDK-AAC)
ffmpeg -i in.mkv -c:v libx265 -preset slow -crf 20 -c:a libfdk_aac -b:a 192k out.mkv
```

### Build your own (any Windows 10/11 x64 box)
```bash
git clone https://github.com/laurentvv/ffmpeg-amd-native-windows.git
cd ffmpeg-amd-native-windows
bash setup.sh                     # portable MSYS2 + toolchain + libs + latest sources (~5 min, ~3 GB)

# Personal build (nonfree, includes FDK-AAC):
MSYSTEM=UCRT64 ../msys64/usr/bin/bash.exe -lc 'bash build.sh'
cd ../build_work && make -j$(nproc) && make install

# Or redistributable GPL build:
MSYSTEM=UCRT64 ../msys64/usr/bin/bash.exe -lc 'bash build_gpl.sh'
cd ../build_work_gpl && make -j$(nproc) && make install
```

One-command maintenance — detects the latest FFmpeg release, refreshes every library, rebuilds, sanity-checks the GPU encoders:
```bash
MSYSTEM=UCRT64 ../msys64/usr/bin/bash.exe -lc 'bash update.sh'   # --force | --dry-run
```

## Project layout
```
├── setup.sh         # One-shot environment (portable MSYS2, GCC 16 UCRT64, ~50 libs)
├── build.sh         # Full personal build (nonfree: +libfdk-aac)
├── build_gpl.sh     # Redistributable GPL build (used for releases)
├── update.sh        # Latest-release detection + full refresh + rebuild + checks
└── pc-override/     # pkg-config overrides that make FULLY-STATIC linking work
    ├── generate.sh  #   regenerates renamed import libs from the local toolchain
    └── *.pc         #   documented fixes, one per linking pitfall
```
Everything is isolated under one root (default `/c/ffmpeg`): nothing is installed system-wide, no registry entries, no `C:\msys64`. Delete the folder = clean uninstall.

## Technical notes — the MSYS2 fully-static pitfalls

Building FFmpeg *fully static* against MSYS2's UCRT64 repositories hits a series of packaging quirks. Each is solved by a documented override in [`pc-override/`](pc-override/README.md):

1. **freetype ↔ harfbuzz circular dependency** → repeat both in `--extra-libs` (static link order)
2. **libplacebo** requires shaderc + SPIRV-Tools; MSYS2's `shaderc_combined` lacks glslang/SPIRV → explicit `-lglslang -lSPIRV -lSPIRV-Tools -lSPIRV-Tools-opt -lSPIRV-Tools` chain (repeated for cross-references)
3. **Vulkan** → import lib copied as `libvulkan_1_sys.a` so `-static` accepts it (links against the *system driver's* `vulkan-1.dll` — the correct runtime model on Windows)
4. **libjxl_cms** is built against *shared* Highway → import `libhwy.dll.a` renamed `libhwy_dll.a`, with `libhwy.dll` shipped next to the binaries (the single bundled DLL)
5. **`-lgcc_s` injected** by srt/gme/x265/haisrt `.pc` files conflicts with `-static-libgcc` → stripped via overrides
6. **dllimport declarations** in libmodplug / libtwolame headers → `-DMODPLUG_STATIC`, `-DLIBTWOLAME_STATIC`
7. **libsoxr** is built with OpenMP → add `-lgomp`
8. **librist** references `libmbedcrypto.dll.a` → redirect to static `-lmbedcrypto`
9. FFmpeg's configure **drops `-Wl,--start-group`** from pkg-config libs → library repetition instead of linker groups

## License
- **This build system (scripts, overrides, docs)**: MIT
- **Produced binaries**: GPL-3.0 (GPL variant) — the *full* variant additionally links libfdk-aac and is therefore **nonfree and not redistributable**; keep it for personal use only.
- FFmpeg and all bundled libraries belong to their respective authors and licenses.

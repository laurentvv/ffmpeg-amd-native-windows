# pkg-config overrides for fully-static linking

These `.pc` files sit *in front* of the MSYS2 UCRT64 pkg-config path
(`export PKG_CONFIG_PATH=$FFROOT/pc-override:...`) and repair the packaging
quirks that break fully-static FFmpeg builds. Each override is documented in
the main README (§ Technical notes). Paths are portable: `${pcfiledir}`.

| Override | Fixes |
|---|---|
| `shaderc.pc` | shaderc_combined lacks glslang/SPIRV-Tools → explicit static chain (SPIRV-Tools repeated for cross-refs) |
| `vulkan.pc` | `-static` refuses `.dll.a` imports → uses renamed copy `libvulkan_1_sys.a` (system driver DLL) |
| `spirv-cross-c-shared.pc` | points to static `libspirv-cross-c.a` |
| `libmodplug.pc` | adds `-DMODPLUG_STATIC` (headers default to dllimport) |
| `libtwolame`* | handled via `-DLIBTWOLAME_STATIC` in build.sh (no pkg-config involved) |
| `librist.pc` | `libmbedcrypto.dll.a` → static `-lmbedcrypto` |
| `libjxl.pc` | appends `libhwy_dll.a` (renamed import; `libhwy.dll` must ship with binaries) |
| `libhwy*.pc` | `-DHWY_SHARED_DEFINE` → `-DHWY_STATIC_DEFINE` |
| `srt.pc`, `haisrt.pc`, `libgme.pc`, `x265.pc` | strip `-lgcc_s` (conflicts with `-static-libgcc`) |

`generate.sh` recreates the two renamed import libraries from the local
toolchain — run it once after `setup.sh` and after any toolchain update.

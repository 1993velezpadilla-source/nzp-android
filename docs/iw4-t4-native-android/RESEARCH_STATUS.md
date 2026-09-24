# IW4 / T4 Native Android Research

This branch is deliberately isolated from Xeno/Xziel. Nothing here is merged
into the engine/game project unless explicitly requested later.

## Goal

Find the strongest publicly available, source-available foundation for a
**native ARM64 Android** proof based on the IW4 (Modern Warfare 2, 2009) or T4
(World at War, 2008) technology family.

Target proof:

```
source-available runtime foundation
        -> remove original-exe dependencies
        -> ARM64 / Android platform layer
        -> native APK
        -> Sanctum/church test map
        -> spawn + movement + collision + rendering
```

Wine/Winlator/emulation is not the target for this branch.

## Current candidate inventory

### OpenIW4/OpenIW4 — primary IW4 reverse-engineering candidate

Pinned commit: `78b2d2e4eeaa592842673a895fc8ed1f9e3e765b`

The project describes itself as an attempt to document and reimplement
important IW4MP functions. It contains 55 C/C++ source/header files in the
current audited tree.

It is **not standalone today**. Its Windows bootstrap explicitly loads
`iw4mp.exe`, and public code search shows `memory::call` thunks in at least
15 source files plus fixed-address globals/casts in at least 20 files. It also
links Win32/D3D9 directly.

The upstream repository contains `runtime/iw4mp.exe`; that executable is not
copied into this research branch.

License reported by upstream: WTFPL v2.

### myraven2256/IW (OpenIW lineage) — secondary IW4 candidate

Pinned commit: `3234d6f7c65ec9ff68bb4ad536c34b17c80023b7`

This is much larger: 1,397 C/C++ source/header files in the audited tree.
It contains gameplay-adjacent implementations for movement, weapons,
animation, aim assist and many engine structures.

It is still **not standalone**. The current bootstrap uses
`Zynamic::Forward(...)` and fixed addresses into an IW4 executable, and its
CMake copies `bin/IW4.exe` into the target MW2 directory.

The upstream executable is not copied into this research branch.

License reported by upstream: GPL-3.0.

### iw4x/iw4x-client — behavioral / structure reference

Pinned commit: `06f3c78bf7a4c62a4866f8bc3b56db2555f2dade`

513 C/C++ source/header files in the audited tree. Extremely useful for IW4
structures, assets, hooks, networking and years of community fixes. It still
requires a valid original MW2 installation and therefore is not a standalone
runtime base.

License reported by upstream: GPL-3.0.

### Laupetin/OpenAssetTools — IW4/T4 asset-format reference

Pinned commit: `209d0105c3330e4d938965f336c7e4892b63a18e`

2,016 C/C++ source/header files in the audited tree. Supports IW4 and T4 asset
formats and custom fastfile tooling. It is tooling rather than a game runtime.
For IW4/T4, several world/collision asset classes are still incomplete for
disk load/build, so it cannot replace the renderer/world runtime by itself.

License reported by upstream: GPL-3.0.

### T4M — T4 runtime-hook reference

Pinned commit: `2306ce31ed5846ca76304a4de6e2029298b67495`

27 C/C++ source/header files. The audited source directly patches CoDWaW
process memory, modifies the PE entry point, uses x86 inline assembly and calls
engine functions through fixed addresses such as `0x00682040`.

It is not a standalone T4 engine.

### T4M-Enhanced

Pinned commit: `2df929cbefabd64075891a3b9eeb69a18158aece`

73 C/C++ source/header files. More extensive than original T4M but still a
DLL/ASI-style extension of CoDWaW.exe. Its repository also contains DirectX SDK
binary tools/libraries, so this research branch records it as a reference only.

### World at War Mod Tools

The public/reuploaded WaW Mod Tools contain map source, scripts, exporters,
zone-source and many authoring assets/tools, but they are not the complete T4
runtime. They are governed by the game/mod-tools EULA rather than a general
open-source license.

## What the internet search established

The existence of custom maps, zombie mods, IW4x and T4M does **not** imply the
community has a complete standalone copy of the original client engine. These
projects can modify enormous portions of a game while still calling into the
original executable for rendering, asset DB, platform, scripting or other
subsystems.

No complete, standalone, openly licensed IW4 or T4 client runtime was found in
the public sources audited so far.

## Best technical path found so far

OpenIW/OpenIW4 give us the most direct head start because real engine/gameplay
functions have already been reconstructed in C++. The native Android experiment
would therefore proceed by eliminating the original-executable dependency
instead of starting from a blank engine.

Immediate order:

1. inventory every remaining thunk/fixed-address dependency;
2. classify by platform, renderer, DB/assets, gameplay, script, network, sound;
3. keep reconstructed C++ where it is already independent;
4. replace thunks with standalone implementations;
5. prove a host process can initialize without loading `iw4mp.exe`;
6. compile that host on a non-Windows desktop target;
7. add ARM64 Android NDK target;
8. replace Win32 window/input/audio/filesystem;
9. replace D3D9 renderer boundary;
10. bring in Sanctum only after runtime initialization is standalone.

## Research boundary

This project may use public source-available reimplementations and documented
formats. It does not store leaked/proprietary Infinity Ward/Treyarch source,
original game executables, fastfiles, IWDs or other game payloads.

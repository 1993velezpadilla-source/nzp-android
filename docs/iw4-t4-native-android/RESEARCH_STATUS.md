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
important IW4MP functions. It contains substantial C++ under `src/`.

It is **not standalone today**. Its current Windows bootstrap explicitly loads
`iw4mp.exe`, and many functions/globals still use hard-coded original-binary
addresses or thunks. The upstream repository also contains
`runtime/iw4mp.exe`; that binary is intentionally excluded from our snapshot.

License reported by upstream: WTFPL v2.

### myraven2256/IW (OpenIW lineage) — secondary IW4 candidate

Pinned commit: `3234d6f7c65ec9ff68bb4ad536c34b17c80023b7`

Contains C++ implementations for gameplay-adjacent systems including movement,
weapons, animation and aim-assist. It is also **not standalone**: the current
code uses `Zynamic::Forward(...)` and fixed addresses into an IW4 executable.
The upstream repository contains `bin/IW4.exe`; that binary is intentionally
excluded from our snapshot.

License reported by upstream: GPL-3.0.

### iw4x/iw4x-client — behavioral / structure reference

Pinned commit: `06f3c78bf7a4c62a4866f8bc3b56db2555f2dade`

Useful for IW4 structures, asset interfaces, hooks, networking/mod behavior and
years of community fixes. It still requires an original MW2 installation and
is therefore not our standalone runtime base.

License reported by upstream: GPL-3.0.

### Laupetin/OpenAssetTools — IW4/T4 asset-format reference

Pinned commit: `209d0105c3330e4d938965f336c7e4892b63a18e`

Supports multiple asset types for both IW4 and T4 and is valuable for building
our asset import/compile path. It is tooling, not a game runtime.

License reported by upstream: GPL-3.0.

### T4M / T4M-Enhanced — T4 runtime-hook references only

Pinned references:

- `iAmThatMichael/T4M@2306ce31ed5846ca76304a4de6e2029298b67495`
- `JBShady/T4M-Enhanced@2df929cbefabd64075891a3b9eeb69a18158aece`

These load as DLL/ASI modifications into World at War. They are useful for
documenting T4 addresses, structs and renderer/game behavior, but are not a
standalone T4 engine. No clear permissive/open-source license was found at the
repository root during this audit, so this branch records references only and
does not mirror their source.

### World at War Mod Tools

The public/reuploaded WaW Mod Tools contain map source, scripts, exporters,
zone-source and many assets/tools, but they are not the complete T4 runtime.
They are governed by the game/mod-tools EULA rather than a general open-source
license, so they are not mirrored into this branch.

## Source snapshot rule

The workflow `.github/workflows/iw4-t4-source-snapshot.yml` mirrors only
source/documentation/build metadata from upstream projects with an explicit
source license.

It rejects common game/runtime payload extensions:

- `.exe`
- `.dll`
- `.ff`
- `.iwd`
- `.asi`
- `.iwi`
- archives such as `.zip/.rar/.7z`

The source snapshots are engineering references, not a claim that any project
is already a portable engine.

## First engineering question

The next milestone is to quantify the dependency on the original Windows
binary. The source census records:

- hard-coded address references;
- `memory::call` thunks;
- `Zynamic::Forward` calls;
- Win32 API usage;
- D3D9 usage;
- source-file counts.

The Android port starts only after those dependencies are explicit enough to
replace subsystem-by-subsystem instead of guessing.

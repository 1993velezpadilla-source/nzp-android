# IW4 Native Research Core

This directory is the standalone runtime experiment for the isolated
IW4/T4-native-Android research branch.

It does **not** load or embed `iw4mp.exe`, `IW4.exe`, `CoDWaW.exe`,
fastfiles, IWDs, or original game assets.

Current standalone slice:

- deterministic memory arena;
- dvar registry;
- command buffer;
- runtime boot lifecycle;
- Linux host executable;
- Android ARM64 JNI shared-library target;
- smoke tests;
- CI guard that rejects original-executable names, fixed-address patterns and
  thunk signatures inside this standalone core.

The current boot target uses `xziel_sanctum` only as a logical map name. It
does not yet render or load Sanctum.

## Gate A

Pass when Linux host prints:

`iw4native.ok=true`

without an original game executable.

## Gate B

Pass when the same core cross-compiles to an AArch64 Android ELF
`libiw4native.so` using the Android NDK.

## Next subsystem slices

After Gates A/B:

1. filesystem abstraction;
2. zone/asset database interface;
3. math/collision primitives;
4. player-movement core;
5. script VM boundary;
6. renderer abstraction;
7. XModel/XAnim/material loading;
8. world/collision data;
9. Sanctum loader;
10. Android app shell/APK.

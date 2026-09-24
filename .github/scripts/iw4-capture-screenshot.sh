#!/usr/bin/env bash
set -euo pipefail
set -x

APK="iw4-native/android-app/app/build/outputs/apk/debug/app-debug.apk"
OUT="dist/iw4-native-sanctum.png"
LOG="dist/iw4-native-logcat.txt"

pwd
ls -lh "$APK"
mkdir -p dist

adb devices -l
adb install -r "$APK"
adb logcat -c || true

# Suppress Android's one-time immersive-mode education overlay so the
# screenshot contains only the actual game surface and HUD.
adb shell settings put secure immersive_mode_confirmations confirmed || true

adb shell am force-stop com.xziel.iw4native || true
adb shell am start -W -n com.xziel.iw4native/.MainActivity

# Give GLSurfaceView, native asset decode, GPU upload and first frame time to settle.
sleep 10

adb shell screencap -p /sdcard/iw4-native-sanctum.png
adb pull /sdcard/iw4-native-sanctum.png "$OUT"
adb logcat -d > "$LOG"

test -s "$OUT"
file "$OUT"
ls -lh "$OUT" "$LOG"

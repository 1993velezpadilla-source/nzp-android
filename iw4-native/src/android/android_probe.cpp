#include "iw4native/runtime.hpp"

#include <android/log.h>
#include <jni.h>

#include <string>

extern "C"
JNIEXPORT jstring JNICALL
Java_com_xziel_iw4native_NativeBridge_bootProbe(
    JNIEnv* env,
    jclass,
    jstring mapName) {

    const char* chars = mapName ? env->GetStringUTFChars(mapName, nullptr) : nullptr;
    const std::string map = chars ? chars : "xziel_sanctum";

    const auto report = iw4native::bootStandalone(
        "android-arm64", map, 32ull * 1024ull * 1024ull);

    if (chars) env->ReleaseStringUTFChars(mapName, chars);

    const std::string message =
        std::string(report.ok ? "PASS " : "FAIL ") +
        report.message +
        " map=" + report.mapName;

    __android_log_print(
        report.ok ? ANDROID_LOG_INFO : ANDROID_LOG_ERROR,
        "IW4Native",
        "%s",
        message.c_str());

    return env->NewStringUTF(message.c_str());
}

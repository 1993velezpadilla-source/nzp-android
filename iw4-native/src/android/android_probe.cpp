#include "iw4native/runtime.hpp"
#include "iw4native/android_renderer.hpp"

#include <android/log.h>
#include <jni.h>

#include <string>

namespace {
constexpr const char* kTag = "IW4Native";
}

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
        kTag,
        "%s",
        message.c_str());

    return env->NewStringUTF(message.c_str());
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_xziel_iw4native_NativeBridge_rendererInit(
    JNIEnv*,
    jclass) {
    return iw4native::android::rendererInit() ? JNI_TRUE : JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_xziel_iw4native_NativeBridge_rendererLoadSanctum(
    JNIEnv* env,
    jclass,
    jbyteArray bytes) {
    if (!bytes) {
        __android_log_print(
            ANDROID_LOG_ERROR,
            kTag,
            "rendererLoadSanctum called with null byte array");
        return JNI_FALSE;
    }

    const jsize size = env->GetArrayLength(bytes);
    if (size <= 0) {
        __android_log_print(
            ANDROID_LOG_ERROR,
            kTag,
            "rendererLoadSanctum called with empty byte array");
        return JNI_FALSE;
    }

    jbyte* data = env->GetByteArrayElements(bytes, nullptr);
    if (!data) {
        __android_log_print(
            ANDROID_LOG_ERROR,
            kTag,
            "rendererLoadSanctum could not map byte array");
        return JNI_FALSE;
    }

    const bool ok = iw4native::android::rendererLoadSanctum(
        reinterpret_cast<const std::byte*>(data),
        static_cast<std::size_t>(size));

    env->ReleaseByteArrayElements(bytes, data, JNI_ABORT);

    __android_log_print(
        ok ? ANDROID_LOG_INFO : ANDROID_LOG_ERROR,
        kTag,
        "rendererLoadSanctum result=%s bytes=%d",
        ok ? "PASS" : "FAIL",
        static_cast<int>(size));

    return ok ? JNI_TRUE : JNI_FALSE;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_xziel_iw4native_NativeBridge_rendererResize(
    JNIEnv*,
    jclass,
    jint width,
    jint height) {
    iw4native::android::rendererResize(width, height);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_xziel_iw4native_NativeBridge_rendererFrame(
    JNIEnv*,
    jclass,
    jfloat moveX,
    jfloat moveY,
    jfloat lookDx,
    jfloat lookDy,
    jboolean fire,
    jboolean ads,
    jboolean jump,
    jboolean reload,
    jboolean use,
    jboolean knife,
    jboolean grenade,
    jboolean slide,
    jboolean pause) {
    iw4native::android::rendererFrame(
        moveX,
        moveY,
        lookDx,
        lookDy,
        fire == JNI_TRUE,
        ads == JNI_TRUE,
        jump == JNI_TRUE,
        reload == JNI_TRUE,
        use == JNI_TRUE,
        knife == JNI_TRUE,
        grenade == JNI_TRUE,
        slide == JNI_TRUE,
        pause == JNI_TRUE);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_xziel_iw4native_NativeBridge_rendererShutdown(
    JNIEnv*,
    jclass) {
    iw4native::android::rendererShutdown();
}

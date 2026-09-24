package com.xziel.iw4native;

public final class NativeBridge {
    static {
        System.loadLibrary("iw4native");
    }

    private NativeBridge() {}

    public static native String bootProbe(String mapName);

    public static native boolean rendererInit();
    public static native boolean rendererLoadSanctum(byte[] bytes);
    public static native void rendererResize(int width, int height);
    public static native void rendererFrame(
        float moveX,
        float moveY,
        float lookDx,
        float lookDy,
        boolean fire,
        boolean ads,
        boolean jump
    );
    public static native void rendererShutdown();
}

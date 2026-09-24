package com.xziel.iw4native;

public final class NativeBridge {
    static {
        System.loadLibrary("iw4native");
    }

    private NativeBridge() {}

    public static native String bootProbe(String mapName);
}

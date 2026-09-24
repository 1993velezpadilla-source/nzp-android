package com.xziel.iw4native;

import android.content.Context;
import android.opengl.GLSurfaceView;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public final class GameSurfaceView extends GLSurfaceView implements GLSurfaceView.Renderer {
    private float moveX;
    private float moveY;
    private float lookDx;
    private float lookDy;
    private boolean fire;
    private boolean ads;
    private boolean jump;
    private volatile boolean rendererReady;

    public GameSurfaceView(Context context) {
        super(context);
        setEGLContextClientVersion(3);
        setPreserveEGLContextOnPause(true);
        setRenderer(this);
        setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
    }

    public synchronized void setMove(float x, float y) {
        moveX = clamp(x);
        moveY = clamp(y);
    }

    public synchronized void addLook(float dx, float dy) {
        lookDx += dx;
        lookDy += dy;
    }

    public synchronized void setButtons(boolean firePressed, boolean adsPressed, boolean jumpPressed) {
        fire = firePressed;
        ads = adsPressed;
        jump = jumpPressed;
    }

    public boolean isRendererReady() {
        return rendererReady;
    }

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        rendererReady = NativeBridge.rendererInit();
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        NativeBridge.rendererResize(width, height);
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        final float mx;
        final float my;
        final float dx;
        final float dy;
        final boolean fireNow;
        final boolean adsNow;
        final boolean jumpNow;

        synchronized (this) {
            mx = moveX;
            my = moveY;
            dx = lookDx;
            dy = lookDy;
            lookDx = 0.0f;
            lookDy = 0.0f;
            fireNow = fire;
            adsNow = ads;
            jumpNow = jump;
        }

        NativeBridge.rendererFrame(mx, my, dx, dy, fireNow, adsNow, jumpNow);
    }

    public void shutdown() {
        queueEvent(NativeBridge::rendererShutdown);
    }

    private static float clamp(float value) {
        return Math.max(-1.0f, Math.min(1.0f, value));
    }
}

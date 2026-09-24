package com.xziel.iw4native;

import android.content.Context;
import android.opengl.GLSurfaceView;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public final class GameSurfaceView extends GLSurfaceView implements GLSurfaceView.Renderer {
    private static final String TAG = "IW4NativeSurface";
    private static final String SANCTUM_ASSET = "maps/sanctum_preview.snp1";

    private final byte[] sanctumPreview;

    private float moveX;
    private float moveY;
    private float lookDx;
    private float lookDy;
    private boolean fire;
    private boolean ads;
    private boolean jump;
    private volatile boolean rendererReady;
    private volatile boolean sanctumLoaded;

    public GameSurfaceView(Context context) {
        super(context);
        sanctumPreview = loadAsset(context, SANCTUM_ASSET);

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

    public boolean isSanctumLoaded() {
        return sanctumLoaded;
    }

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        rendererReady = NativeBridge.rendererInit();
        sanctumLoaded = false;

        if (!rendererReady) {
            Log.e(TAG, "Native GLES3 renderer initialization failed");
            return;
        }

        if (sanctumPreview == null || sanctumPreview.length == 0) {
            Log.e(TAG, "Packaged Sanctum preview asset is missing; using fallback room");
            return;
        }

        sanctumLoaded = NativeBridge.rendererLoadSanctum(sanctumPreview);
        Log.i(
            TAG,
            "Sanctum upload " + (sanctumLoaded ? "PASS" : "FAIL") +
            " bytes=" + sanctumPreview.length
        );
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

    private static byte[] loadAsset(Context context, String path) {
        try (
            InputStream input = context.getAssets().open(path);
            ByteArrayOutputStream output = new ByteArrayOutputStream()
        ) {
            final byte[] buffer = new byte[16 * 1024];
            int read;
            while ((read = input.read(buffer)) >= 0) {
                if (read > 0) output.write(buffer, 0, read);
            }
            return output.toByteArray();
        } catch (IOException error) {
            Log.e(TAG, "Failed to read asset " + path, error);
            return null;
        }
    }

    private static float clamp(float value) {
        return Math.max(-1.0f, Math.min(1.0f, value));
    }
}

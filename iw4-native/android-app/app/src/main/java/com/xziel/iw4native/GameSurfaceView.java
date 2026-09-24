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
    public interface StatusListener {
        void onStatus(String text, boolean good);
    }

    private static final String TAG = "IW4NativeSurface";
    private static final String SANCTUM_ASSET = "maps/sanctum_preview.snp1";

    private final byte[] sanctumPreview;
    private final StatusListener statusListener;

    private float moveX;
    private float moveY;
    private float lookDx;
    private float lookDy;

    private boolean fire;
    private boolean ads;
    private boolean jump;
    private boolean reload;
    private boolean use;
    private boolean knife;
    private boolean grenade;
    private boolean slide;
    private boolean pause;

    private volatile boolean rendererReady;
    private volatile boolean sanctumLoaded;

    public GameSurfaceView(Context context, StatusListener statusListener) {
        super(context);
        this.statusListener = statusListener;
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

    public synchronized void setButtons(
        boolean firePressed,
        boolean adsPressed,
        boolean jumpPressed,
        boolean reloadPressed,
        boolean usePressed,
        boolean knifePressed,
        boolean grenadePressed,
        boolean slidePressed,
        boolean pausePressed
    ) {
        fire = firePressed;
        ads = adsPressed;
        jump = jumpPressed;
        reload = reloadPressed;
        use = usePressed;
        knife = knifePressed;
        grenade = grenadePressed;
        slide = slidePressed;
        pause = pausePressed;
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
            publishStatus("RENDERER INIT FAIL", false);
            return;
        }

        if (sanctumPreview == null || sanctumPreview.length == 0) {
            Log.e(TAG, "Packaged Sanctum preview asset is missing; using fallback room");
            publishStatus("SANCTUM ASSET MISSING  •  FALLBACK ROOM", false);
            return;
        }

        sanctumLoaded = NativeBridge.rendererLoadSanctum(sanctumPreview);

        final String status =
            sanctumLoaded
                ? "SANCTUM 24K PASS  •  " + sanctumPreview.length + " BYTES"
                : "SANCTUM LOAD FAIL  •  FALLBACK ROOM";

        Log.i(TAG, status);
        publishStatus(status, sanctumLoaded);
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
        final boolean reloadNow;
        final boolean useNow;
        final boolean knifeNow;
        final boolean grenadeNow;
        final boolean slideNow;
        final boolean pauseNow;

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
            reloadNow = reload;
            useNow = use;
            knifeNow = knife;
            grenadeNow = grenade;
            slideNow = slide;
            pauseNow = pause;
        }

        NativeBridge.rendererFrame(
            mx,
            my,
            dx,
            dy,
            fireNow,
            adsNow,
            jumpNow,
            reloadNow,
            useNow,
            knifeNow,
            grenadeNow,
            slideNow,
            pauseNow
        );
    }

    public void shutdown() {
        queueEvent(NativeBridge::rendererShutdown);
    }

    private void publishStatus(String text, boolean good) {
        if (statusListener == null) return;
        post(() -> statusListener.onStatus(text, good));
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

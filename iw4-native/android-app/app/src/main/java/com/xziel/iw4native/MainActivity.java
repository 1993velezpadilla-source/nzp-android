package com.xziel.iw4native;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.TextView;

public final class MainActivity extends Activity {
    private GameSurfaceView gameView;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        enterImmersive();

        final String bootStatus;
        try {
            bootStatus = NativeBridge.bootProbe("xziel_sanctum");
        } catch (Throwable error) {
            throw new IllegalStateException("Native boot failed", error);
        }

        final FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.rgb(12, 15, 19));

        final TextView status = new TextView(this);
        status.setText(
            "IW4 NATIVE ARM64  •  SANCTUM  •  NZP RADIAL TOUCH\n" +
            bootStatus + "\n" +
            "RENDERER STARTING..."
        );
        status.setTextColor(Color.argb(220, 255, 255, 255));
        status.setTextSize(9.5f);
        status.setGravity(Gravity.START);
        status.setPadding(18, 10, 18, 10);
        status.setBackgroundColor(Color.argb(105, 0, 0, 0));

        gameView = new GameSurfaceView(
            this,
            (text, good) -> {
                status.setText(
                    "IW4 NATIVE ARM64  •  SANCTUM  •  NZP RADIAL TOUCH\n" +
                    bootStatus + "\n" +
                    text
                );
                status.setTextColor(
                    good
                        ? Color.rgb(200, 240, 160)
                        : Color.rgb(255, 125, 105)
                );
            }
        );

        root.addView(
            gameView,
            new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        );

        final TouchHudView hud = new TouchHudView(this, gameView);
        root.addView(
            hud,
            new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        );

        final FrameLayout.LayoutParams statusParams =
            new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.TOP | Gravity.LEFT
            );
        root.addView(status, statusParams);

        setContentView(root);
    }

    @Override
    protected void onResume() {
        super.onResume();
        enterImmersive();
        if (gameView != null) gameView.onResume();
    }

    @Override
    protected void onPause() {
        if (gameView != null) gameView.onPause();
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        if (gameView != null) gameView.shutdown();
        super.onDestroy();
    }

    private void enterImmersive() {
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        );
    }
}

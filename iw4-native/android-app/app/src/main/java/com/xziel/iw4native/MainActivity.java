package com.xziel.iw4native;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);

        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        );

        final LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER);
        root.setPadding(48, 48, 48, 48);
        root.setBackgroundColor(Color.rgb(8, 10, 12));

        final TextView title = new TextView(this);
        title.setText("IW4 NATIVE ANDROID");
        title.setTextColor(Color.WHITE);
        title.setTextSize(28);
        title.setGravity(Gravity.CENTER);

        final TextView subtitle = new TextView(this);
        subtitle.setText("Standalone ARM64 runtime probe\nNo Wine · No Winlator · No Windows EXE");
        subtitle.setTextColor(Color.LTGRAY);
        subtitle.setTextSize(16);
        subtitle.setGravity(Gravity.CENTER);
        subtitle.setPadding(0, 24, 0, 24);

        final TextView result = new TextView(this);
        result.setTextColor(Color.WHITE);
        result.setTextSize(18);
        result.setGravity(Gravity.CENTER);
        result.setText("Booting native core...");

        root.addView(title);
        root.addView(subtitle);
        root.addView(result);
        setContentView(root);

        try {
            result.setText(NativeBridge.bootProbe("xziel_sanctum"));
        } catch (Throwable error) {
            result.setText("FAIL\n" + error.getClass().getSimpleName() + ": " + error.getMessage());
        }
    }
}

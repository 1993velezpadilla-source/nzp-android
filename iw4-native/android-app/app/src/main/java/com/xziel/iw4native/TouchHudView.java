package com.xziel.iw4native;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PointF;
import android.graphics.RectF;
import android.util.SparseArray;
import android.util.SparseIntArray;
import android.view.MotionEvent;
import android.view.View;

public final class TouchHudView extends View {
    private static final int NONE = 0;
    private static final int MOVE = 1;
    private static final int LOOK = 2;
    private static final int FIRE = 3;
    private static final int ADS_FIRE = 4;
    private static final int ADS = 5;
    private static final int RELOAD = 6;
    private static final int USE = 7;
    private static final int JUMP = 8;
    private static final int KNIFE = 9;
    private static final int GRENADE = 10;
    private static final int SLIDE = 11;
    private static final int PAUSE = 12;

    private static final float JOY_X = 0.170f;
    private static final float JOY_Y = 0.740f;
    private static final float FIRE_X = 0.885f;
    private static final float FIRE_Y = 0.585f;
    private static final float ADS_FIRE_X = 0.795f;
    private static final float ADS_FIRE_Y = 0.435f;
    private static final float ADS_X = 0.695f;
    private static final float ADS_Y = 0.575f;
    private static final float RELOAD_X = 0.805f;
    private static final float RELOAD_Y = 0.785f;
    private static final float USE_X = 0.605f;
    private static final float USE_Y = 0.675f;
    private static final float JUMP_X = 0.695f;
    private static final float JUMP_Y = 0.790f;
    private static final float KNIFE_X = 0.915f;
    private static final float KNIFE_Y = 0.800f;
    private static final float GRENADE_X = 0.835f;
    private static final float GRENADE_Y = 0.300f;
    private static final float SLIDE_X = 0.745f;
    private static final float SLIDE_Y = 0.825f;
    private static final float PAUSE_X = 0.965f;
    private static final float PAUSE_Y = 0.075f;

    private static final float HUD_OPACITY = 0.72f;

    private final GameSurfaceView game;
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final SparseIntArray pointerRoles = new SparseIntArray();
    private final SparseArray<PointF> pointerLast = new SparseArray<>();

    private float moveX;
    private float moveY;
    private boolean firePressed;
    private boolean adsFirePressed;
    private boolean adsPressed;
    private boolean reloadPressed;
    private boolean usePressed;
    private boolean jumpPressed;
    private boolean knifePressed;
    private boolean grenadePressed;
    private boolean slidePressed;
    private boolean pausePressed;

    public TouchHudView(Context context, GameSurfaceView game) {
        super(context);
        this.game = game;
        setWillNotDraw(false);
        setBackgroundColor(Color.TRANSPARENT);

        paint.setTypeface(android.graphics.Typeface.create(
            android.graphics.Typeface.SANS_SERIF,
            android.graphics.Typeface.BOLD
        ));
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeCap(Paint.Cap.ROUND);
        stroke.setStrokeJoin(Paint.Join.ROUND);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (getWidth() <= 0 || getHeight() <= 0) return;

        drawCrosshair(canvas);
        drawJoystick(canvas);

        drawButton(canvas, FIRE_X, FIRE_Y, 0.073f, "FIRE", firePressed);
        drawButton(canvas, ADS_FIRE_X, ADS_FIRE_Y, 0.056f, "ADSFIRE", adsFirePressed);
        drawButton(canvas, ADS_X, ADS_Y, 0.047f, "ADS", adsPressed);
        drawButton(canvas, RELOAD_X, RELOAD_Y, 0.044f, "RLD", reloadPressed);
        drawButton(canvas, USE_X, USE_Y, 0.050f, "USE", usePressed);
        drawButton(canvas, JUMP_X, JUMP_Y, 0.044f, "JUMP", jumpPressed);
        drawButton(canvas, KNIFE_X, KNIFE_Y, 0.044f, "KNIFE", knifePressed);
        drawButton(canvas, GRENADE_X, GRENADE_Y, 0.041f, "NADE", grenadePressed);
        drawButton(canvas, SLIDE_X, SLIDE_Y, 0.044f, "SLIDE", slidePressed);
        drawButton(canvas, PAUSE_X, PAUSE_Y, 0.036f, "II", pausePressed);

        drawWeaponStrip(canvas);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        final int action = event.getActionMasked();
        final int actionIndex = event.getActionIndex();

        if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_POINTER_DOWN) {
            final int id = event.getPointerId(actionIndex);
            final float x = event.getX(actionIndex);
            final float y = event.getY(actionIndex);
            final int role = hitRole(x, y);

            pointerRoles.put(id, role);
            pointerLast.put(id, new PointF(x, y));
            if (role == MOVE) updateMove(x, y);
            syncButtons();
            invalidate();
            return true;
        }

        if (action == MotionEvent.ACTION_MOVE) {
            for (int i = 0; i < event.getPointerCount(); ++i) {
                final int id = event.getPointerId(i);
                final int role = pointerRoles.get(id, NONE);
                final float x = event.getX(i);
                final float y = event.getY(i);
                final PointF last = pointerLast.get(id);

                if (role == MOVE) {
                    updateMove(x, y);
                } else if (role == LOOK || role == FIRE || role == ADS ||
                           role == ADS_FIRE) {
                    if (last != null) {
                        game.addLook(x - last.x, y - last.y);
                    }
                }

                if (last != null) {
                    last.set(x, y);
                } else {
                    pointerLast.put(id, new PointF(x, y));
                }
            }

            syncButtons();
            invalidate();
            return true;
        }

        if (action == MotionEvent.ACTION_UP ||
            action == MotionEvent.ACTION_POINTER_UP ||
            action == MotionEvent.ACTION_CANCEL) {
            if (action == MotionEvent.ACTION_CANCEL) {
                pointerRoles.clear();
                pointerLast.clear();
                moveX = 0.0f;
                moveY = 0.0f;
                game.setMove(0.0f, 0.0f);
            } else {
                final int id = event.getPointerId(actionIndex);
                if (pointerRoles.get(id, NONE) == MOVE) {
                    moveX = 0.0f;
                    moveY = 0.0f;
                    game.setMove(0.0f, 0.0f);
                }
                pointerRoles.delete(id);
                pointerLast.remove(id);
            }

            syncButtons();
            invalidate();
            return true;
        }

        return true;
    }

    private int hitRole(float px, float py) {
        if (inside(px, py, PAUSE_X, PAUSE_Y, 0.055f)) return PAUSE;
        if (inside(px, py, FIRE_X, FIRE_Y, 0.090f)) return FIRE;
        if (inside(px, py, ADS_FIRE_X, ADS_FIRE_Y, 0.075f)) return ADS_FIRE;
        if (inside(px, py, ADS_X, ADS_Y, 0.065f)) return ADS;
        if (inside(px, py, RELOAD_X, RELOAD_Y, 0.060f)) return RELOAD;
        if (inside(px, py, USE_X, USE_Y, 0.065f)) return USE;
        if (inside(px, py, GRENADE_X, GRENADE_Y, 0.057f)) return GRENADE;
        if (inside(px, py, JUMP_X, JUMP_Y, 0.060f)) return JUMP;
        if (inside(px, py, SLIDE_X, SLIDE_Y, 0.060f)) return SLIDE;
        if (inside(px, py, KNIFE_X, KNIFE_Y, 0.060f)) return KNIFE;
        if (inside(px, py, JOY_X, JOY_Y, 0.150f)) return MOVE;
        if (px > getWidth() * 0.45f) return LOOK;
        return NONE;
    }

    private boolean inside(float px, float py, float nx, float ny, float radiusH) {
        final float cx = nx * getWidth();
        final float cy = ny * getHeight();
        final float r = radiusH * getHeight();
        final float dx = px - cx;
        final float dy = py - cy;
        return dx * dx + dy * dy <= r * r;
    }

    private void updateMove(float px, float py) {
        final float cx = JOY_X * getWidth();
        final float cy = JOY_Y * getHeight();
        final float radius = 0.105f * getHeight();

        float dx = (px - cx) / radius;
        float dy = (py - cy) / radius;
        final float length = (float)Math.sqrt(dx * dx + dy * dy);
        if (length > 1.0f) {
            dx /= length;
            dy /= length;
        }

        moveX = dx;
        moveY = dy;
        game.setMove(moveX, moveY);
    }

    private void syncButtons() {
        firePressed = false;
        adsFirePressed = false;
        adsPressed = false;
        reloadPressed = false;
        usePressed = false;
        jumpPressed = false;
        knifePressed = false;
        grenadePressed = false;
        slidePressed = false;
        pausePressed = false;

        for (int i = 0; i < pointerRoles.size(); ++i) {
            switch (pointerRoles.valueAt(i)) {
                case FIRE: firePressed = true; break;
                case ADS_FIRE: adsFirePressed = true; break;
                case ADS: adsPressed = true; break;
                case RELOAD: reloadPressed = true; break;
                case USE: usePressed = true; break;
                case JUMP: jumpPressed = true; break;
                case KNIFE: knifePressed = true; break;
                case GRENADE: grenadePressed = true; break;
                case SLIDE: slidePressed = true; break;
                case PAUSE: pausePressed = true; break;
                default: break;
            }
        }

        game.setButtons(
            firePressed || adsFirePressed,
            adsPressed || adsFirePressed,
            jumpPressed,
            reloadPressed,
            usePressed,
            knifePressed,
            grenadePressed,
            slidePressed,
            pausePressed
        );
    }

    private void drawJoystick(Canvas canvas) {
        final float cx = JOY_X * getWidth();
        final float cy = JOY_Y * getHeight();
        final float outer = 0.105f * getHeight();
        final float knob = 0.052f * getHeight();

        paint.setColor(Color.argb((int)(72 * HUD_OPACITY), 235, 235, 235));
        canvas.drawCircle(cx, cy, outer, paint);
        paint.setColor(Color.argb((int)(118 * HUD_OPACITY), 8, 8, 8));
        canvas.drawCircle(cx, cy, outer - Math.max(2.0f, getHeight() * 0.0022f), paint);

        final float kx = cx + moveX * outer * 0.62f;
        final float ky = cy + moveY * outer * 0.62f;
        paint.setColor(Color.argb((int)(125 * HUD_OPACITY), 235, 235, 235));
        canvas.drawCircle(kx, ky, knob, paint);
        paint.setColor(Color.argb((int)(150 * HUD_OPACITY), 12, 12, 12));
        canvas.drawCircle(kx, ky, knob - Math.max(2.0f, getHeight() * 0.002f), paint);
    }

    private void drawButton(Canvas canvas,
                            float nx,
                            float ny,
                            float radiusH,
                            String glyph,
                            boolean pressed) {
        final float cx = nx * getWidth();
        final float cy = ny * getHeight();
        final float radius = Math.max(10.0f, radiusH * getHeight());
        final float border = Math.max(2.0f, getHeight() * 0.002f);

        paint.setColor(Color.argb(
            (int)((pressed ? 155 : 95) * HUD_OPACITY),
            235, 235, 235
        ));
        canvas.drawCircle(cx, cy, radius, paint);

        paint.setColor(Color.argb(
            (int)((pressed ? 175 : 115) * HUD_OPACITY),
            pressed ? 110 : 8,
            pressed ? 18 : 8,
            pressed ? 18 : 8
        ));
        canvas.drawCircle(cx, cy, radius - border, paint);

        drawGlyph(canvas, cx, cy, radius, glyph, pressed);
    }

    private void drawGlyph(Canvas canvas,
                           float cx,
                           float cy,
                           float radius,
                           String glyph,
                           boolean pressed) {
        final int alpha = pressed ? 255 : 225;
        final float t = Math.max(2.0f, getHeight() * 0.0023f);

        stroke.setColor(Color.argb(alpha, 255, 255, 255));
        stroke.setStrokeWidth(t);
        stroke.setStyle(Paint.Style.STROKE);
        paint.setColor(Color.argb(alpha, 255, 255, 255));

        switch (glyph) {
            case "II":
                paint.setStrokeWidth(1.0f);
                canvas.drawRect(cx - radius * 0.24f, cy - radius * 0.33f,
                    cx - radius * 0.08f, cy + radius * 0.33f, paint);
                canvas.drawRect(cx + radius * 0.08f, cy - radius * 0.33f,
                    cx + radius * 0.24f, cy + radius * 0.33f, paint);
                return;

            case "FIRE":
                canvas.drawCircle(cx, cy, radius * 0.10f, paint);
                canvas.drawLine(cx - radius * 0.55f, cy, cx - radius * 0.20f, cy, stroke);
                canvas.drawLine(cx + radius * 0.20f, cy, cx + radius * 0.55f, cy, stroke);
                canvas.drawLine(cx, cy - radius * 0.55f, cx, cy - radius * 0.20f, stroke);
                canvas.drawLine(cx, cy + radius * 0.20f, cx, cy + radius * 0.55f, stroke);
                return;

            case "ADS":
            case "ADSFIRE":
                canvas.drawCircle(cx, cy, radius * 0.42f, stroke);
                canvas.drawLine(cx - radius * 0.62f, cy, cx - radius * 0.36f, cy, stroke);
                canvas.drawLine(cx + radius * 0.36f, cy, cx + radius * 0.62f, cy, stroke);
                canvas.drawLine(cx, cy - radius * 0.62f, cx, cy - radius * 0.36f, stroke);
                canvas.drawLine(cx, cy + radius * 0.36f, cx, cy + radius * 0.62f, stroke);
                if ("ADSFIRE".equals(glyph)) {
                    stroke.setStrokeWidth(t * 1.5f);
                    canvas.drawLine(cx + radius * 0.20f, cy + radius * 0.25f,
                        cx + radius * 0.55f, cy + radius * 0.25f, stroke);
                }
                return;

            case "RLD":
                final RectF reloadArc = new RectF(
                    cx - radius * 0.40f, cy - radius * 0.40f,
                    cx + radius * 0.40f, cy + radius * 0.40f
                );
                canvas.drawArc(reloadArc, 35.0f, 285.0f, false, stroke);
                final Path arrow = new Path();
                arrow.moveTo(cx + radius * 0.39f, cy - radius * 0.15f);
                arrow.lineTo(cx + radius * 0.52f, cy - radius * 0.03f);
                arrow.lineTo(cx + radius * 0.31f, cy + radius * 0.02f);
                arrow.close();
                canvas.drawPath(arrow, paint);
                return;

            case "USE":
                canvas.drawRect(cx - radius * 0.24f, cy - radius * 0.05f,
                    cx + radius * 0.25f, cy + radius * 0.42f, paint);
                canvas.drawLine(cx - radius * 0.28f, cy - radius * 0.35f,
                    cx - radius * 0.28f, cy + radius * 0.04f, stroke);
                canvas.drawLine(cx, cy - radius * 0.42f,
                    cx, cy + radius * 0.02f, stroke);
                canvas.drawLine(cx + radius * 0.26f, cy - radius * 0.34f,
                    cx + radius * 0.26f, cy + radius * 0.06f, stroke);
                return;

            case "JUMP":
                canvas.drawLine(cx, cy + radius * 0.42f, cx, cy - radius * 0.42f, stroke);
                canvas.drawLine(cx, cy - radius * 0.42f,
                    cx - radius * 0.28f, cy - radius * 0.12f, stroke);
                canvas.drawLine(cx, cy - radius * 0.42f,
                    cx + radius * 0.28f, cy - radius * 0.12f, stroke);
                return;

            case "KNIFE":
                stroke.setStrokeWidth(t * 1.7f);
                canvas.drawLine(cx - radius * 0.48f, cy + radius * 0.25f,
                    cx + radius * 0.35f, cy - radius * 0.20f, stroke);
                stroke.setStrokeWidth(t * 2.6f);
                canvas.drawLine(cx + radius * 0.20f, cy - radius * 0.32f,
                    cx + radius * 0.43f, cy + radius * 0.03f, stroke);
                return;

            case "NADE":
                canvas.drawCircle(cx, cy + radius * 0.12f, radius * 0.34f, stroke);
                canvas.drawLine(cx, cy - radius * 0.22f, cx, cy - radius * 0.48f, stroke);
                canvas.drawLine(cx, cy - radius * 0.48f,
                    cx + radius * 0.28f, cy - radius * 0.48f, stroke);
                return;

            case "SLIDE":
                canvas.drawLine(cx - radius * 0.45f, cy - radius * 0.18f,
                    cx + radius * 0.12f, cy + radius * 0.20f, stroke);
                canvas.drawLine(cx + radius * 0.12f, cy + radius * 0.20f,
                    cx + radius * 0.46f, cy + radius * 0.20f, stroke);
                canvas.drawCircle(cx - radius * 0.30f, cy - radius * 0.35f,
                    radius * 0.11f, paint);
                return;

            default:
                paint.setTextAlign(Paint.Align.CENTER);
                paint.setTextSize(radius * 0.55f);
                canvas.drawText(glyph, cx, cy + radius * 0.18f, paint);
        }
    }

    private void drawCrosshair(Canvas canvas) {
        final float cx = getWidth() * 0.5f;
        final float cy = getHeight() * 0.5f;
        final float gap = Math.max(5.0f, getHeight() * 0.007f);
        final float len = Math.max(8.0f, getHeight() * 0.012f);

        stroke.setColor(Color.argb(205, 255, 255, 255));
        stroke.setStrokeWidth(Math.max(1.5f, getHeight() * 0.0016f));
        canvas.drawLine(cx - gap - len, cy, cx - gap, cy, stroke);
        canvas.drawLine(cx + gap, cy, cx + gap + len, cy, stroke);
        canvas.drawLine(cx, cy - gap - len, cx, cy - gap, stroke);
        canvas.drawLine(cx, cy + gap, cx, cy + gap + len, stroke);
    }

    private void drawWeaponStrip(Canvas canvas) {
        final float baseX = getWidth() * 0.50f;
        final float baseY = getHeight() * 0.885f;
        drawWeaponCard(canvas, baseX - getWidth() * 0.115f, baseY,
            getWidth() * 0.150f, getHeight() * 0.100f, "PRIMARY", "30 / 180", true);
        drawWeaponCard(canvas, baseX + getWidth() * 0.025f, baseY,
            getWidth() * 0.110f, getHeight() * 0.080f, "SECOND", "12 / 48", false);
        drawWeaponCard(canvas, baseX + getWidth() * 0.145f, baseY,
            getWidth() * 0.110f, getHeight() * 0.080f, "PISTOL", "8 / 64", false);
    }

    private void drawWeaponCard(Canvas canvas,
                                float cx,
                                float cy,
                                float width,
                                float height,
                                String name,
                                String ammo,
                                boolean active) {
        final float left = cx - width * 0.5f;
        final float top = cy - height * 0.5f;
        final float border = Math.max(1.0f, getHeight() * 0.002f);

        paint.setColor(Color.argb((int)((active ? 185 : 135) * HUD_OPACITY), 4, 4, 4));
        canvas.drawRect(left, top, left + width, top + height, paint);

        paint.setColor(Color.argb(220,
            active ? 255 : 190,
            active ? 205 : 190,
            active ? 40 : 190));
        canvas.drawRect(left, top, left + width, top + border, paint);
        canvas.drawRect(left, top + height - border, left + width, top + height, paint);

        paint.setTextAlign(Paint.Align.CENTER);
        paint.setTextSize(Math.max(10.0f, height * 0.24f));
        paint.setColor(Color.argb(215, 235, 235, 235));
        canvas.drawText(name, cx, cy - height * 0.05f, paint);

        paint.setTextSize(Math.max(9.0f, height * 0.20f));
        paint.setColor(Color.argb(230, 255, 255, 255));
        canvas.drawText(ammo, cx, cy + height * 0.30f, paint);
    }
}

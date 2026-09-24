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

/**
 * NZP-inspired mobile HUD.
 *
 * Visual contract from the original reference:
 * - large translucent grey action wheel on the right;
 * - bright yellow/lime outer ring;
 * - dark circular action cells inside the wheel;
 * - white pictogram glyphs;
 * - center FIRE cartridge with yellow focus ring;
 * - separate AIM crosshair and AIM+FIRE crosshair+cartridge;
 * - stance / weapon / reload / switch controls arranged radially;
 * - independent left movement joystick.
 */
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

    private static final float JOY_X = 0.155f;
    private static final float JOY_Y = 0.765f;

    // Right radial wheel. Values intentionally derive from screen height so
    // the proportions remain close to the original NZP skin across aspect ratios.
    private static final float WHEEL_X = 0.830f;
    private static final float WHEEL_Y = 0.615f;
    private static final float WHEEL_R_H = 0.245f;

    private static final int YELLOW = Color.rgb(226, 235, 18);
    private static final int WHITE = Color.rgb(250, 250, 250);

    private final GameSurfaceView game;
    private final Paint fill = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
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

        fill.setStyle(Paint.Style.FILL);
        fill.setStrokeCap(Paint.Cap.ROUND);
        fill.setStrokeJoin(Paint.Join.ROUND);

        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeCap(Paint.Cap.ROUND);
        stroke.setStrokeJoin(Paint.Join.ROUND);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (getWidth() <= 0 || getHeight() <= 0) return;

        drawWorldCrosshair(canvas);
        drawJoystick(canvas);
        drawActionWheel(canvas);
        drawPause(canvas);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        final int action = event.getActionMasked();
        final int actionIndex = event.getActionIndex();

        if (action == MotionEvent.ACTION_DOWN ||
            action == MotionEvent.ACTION_POINTER_DOWN) {
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
                } else if (role == LOOK || role == FIRE ||
                           role == ADS || role == ADS_FIRE) {
                    if (last != null) {
                        game.addLook(x - last.x, y - last.y);
                    }
                }

                if (last == null) {
                    pointerLast.put(id, new PointF(x, y));
                } else {
                    last.set(x, y);
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

    private float wheelCx() {
        return WHEEL_X * getWidth();
    }

    private float wheelCy() {
        return WHEEL_Y * getHeight();
    }

    private float wheelR() {
        return WHEEL_R_H * getHeight();
    }

    private float buttonR() {
        return wheelR() * 0.178f;
    }

    private float buttonX(float dx) {
        return wheelCx() + dx * wheelR();
    }

    private float buttonY(float dy) {
        return wheelCy() + dy * wheelR();
    }

    private int hitRole(float px, float py) {
        final float r = buttonR() * 1.08f;

        if (circleHit(px, py, getWidth() * 0.962f, getHeight() * 0.080f,
            getHeight() * 0.047f)) return PAUSE;

        // Match the radial reference: aim upper-left, reload upper-right,
        // fire in the highlighted centre, bullet/aim combo on right.
        if (circleHit(px, py, buttonX(-0.43f), buttonY(-0.52f), r)) return ADS;
        if (circleHit(px, py, buttonX( 0.32f), buttonY(-0.52f), r)) return RELOAD;
        if (circleHit(px, py, buttonX( 0.00f), buttonY(-0.02f), r * 1.13f)) return FIRE;
        if (circleHit(px, py, buttonX( 0.52f), buttonY(-0.03f), r)) return ADS_FIRE;
        if (circleHit(px, py, buttonX(-0.53f), buttonY( 0.03f), r)) return JUMP;
        if (circleHit(px, py, buttonX(-0.56f), buttonY( 0.47f), r)) return SLIDE;
        if (circleHit(px, py, buttonX( 0.02f), buttonY( 0.50f), r * 1.20f)) return KNIFE;
        if (circleHit(px, py, buttonX( 0.61f), buttonY( 0.42f), r * 0.88f)) return USE;
        if (circleHit(px, py, buttonX(-0.13f), buttonY( 0.76f), r * 0.73f)) return GRENADE;

        final float joyCx = JOY_X * getWidth();
        final float joyCy = JOY_Y * getHeight();
        if (circleHit(px, py, joyCx, joyCy, getHeight() * 0.145f)) return MOVE;

        // Empty right-side space is free-look, including unused wheel gaps.
        if (px > getWidth() * 0.45f) return LOOK;
        return NONE;
    }

    private static boolean circleHit(
        float px, float py, float cx, float cy, float radius) {
        final float dx = px - cx;
        final float dy = py - cy;
        return dx * dx + dy * dy <= radius * radius;
    }

    private void updateMove(float px, float py) {
        final float cx = JOY_X * getWidth();
        final float cy = JOY_Y * getHeight();
        final float radius = getHeight() * 0.105f;

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
        final float outer = getHeight() * 0.105f;
        final float inner = outer * 0.48f;

        fill.setColor(Color.argb(74, 120, 120, 120));
        canvas.drawCircle(cx, cy, outer, fill);

        stroke.setStrokeWidth(Math.max(2.0f, getHeight() * 0.0022f));
        stroke.setColor(Color.argb(80, 215, 215, 215));
        canvas.drawCircle(cx, cy, outer, stroke);

        final float knobX = cx + moveX * outer * 0.57f;
        final float knobY = cy + moveY * outer * 0.57f;

        fill.setColor(Color.argb(120, 74, 74, 74));
        canvas.drawCircle(knobX, knobY, inner, fill);
        stroke.setColor(Color.argb(120, 190, 190, 190));
        canvas.drawCircle(knobX, knobY, inner, stroke);
    }

    private void drawActionWheel(Canvas canvas) {
        final float cx = wheelCx();
        final float cy = wheelCy();
        final float radius = wheelR();

        // Smoky translucent background from the NZP reference.
        fill.setColor(Color.argb(82, 118, 118, 108));
        canvas.drawCircle(cx, cy, radius, fill);

        // Soft inner dark tint.
        fill.setColor(Color.argb(38, 20, 20, 18));
        canvas.drawCircle(cx, cy, radius * 0.94f, fill);

        // The defining neon yellow/lime ring.
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeWidth(Math.max(4.0f, getHeight() * 0.0055f));
        stroke.setColor(Color.argb(240, 226, 235, 18));
        canvas.drawCircle(cx, cy, radius * 0.985f, stroke);

        // Cells arranged like the reference screenshot.
        drawCell(canvas, buttonX(-0.43f), buttonY(-0.52f), buttonR(),
            adsPressed, false, ICON_AIM);
        drawCell(canvas, buttonX( 0.32f), buttonY(-0.52f), buttonR(),
            reloadPressed, false, ICON_RELOAD_BULLETS);
        drawCell(canvas, buttonX(-0.53f), buttonY( 0.03f), buttonR(),
            jumpPressed, false, ICON_RUN);
        drawCell(canvas, buttonX(-0.56f), buttonY( 0.47f), buttonR(),
            slidePressed, false, ICON_CROUCH);
        drawCell(canvas, buttonX( 0.52f), buttonY(-0.03f), buttonR(),
            adsFirePressed, false, ICON_AIM_FIRE);
        drawCell(canvas, buttonX( 0.61f), buttonY( 0.42f), buttonR() * 0.88f,
            usePressed, false, ICON_SWITCH);
        drawCell(canvas, buttonX(-0.13f), buttonY( 0.76f), buttonR() * 0.73f,
            grenadePressed, false, ICON_GRENADE);

        // Main center FIRE is larger and gets its own yellow ring.
        drawCell(canvas, buttonX(0.00f), buttonY(-0.02f), buttonR() * 1.13f,
            firePressed, true, ICON_BULLET);

        // Large weapon/melee silhouette on the bottom, as in the reference.
        drawCell(canvas, buttonX(0.02f), buttonY(0.50f), buttonR() * 1.20f,
            knifePressed, false, ICON_WEAPON);
    }

    private static final int ICON_AIM = 1;
    private static final int ICON_RELOAD_BULLETS = 2;
    private static final int ICON_BULLET = 3;
    private static final int ICON_AIM_FIRE = 4;
    private static final int ICON_RUN = 5;
    private static final int ICON_CROUCH = 6;
    private static final int ICON_WEAPON = 7;
    private static final int ICON_SWITCH = 8;
    private static final int ICON_GRENADE = 9;

    private void drawCell(
        Canvas canvas,
        float cx,
        float cy,
        float radius,
        boolean pressed,
        boolean highlighted,
        int icon) {

        // Subtle rim.
        fill.setColor(Color.argb(105, 150, 150, 145));
        canvas.drawCircle(cx, cy, radius, fill);

        // Dark charcoal center, exactly the visual language in the reference.
        fill.setColor(pressed
            ? Color.argb(220, 52, 52, 45)
            : Color.argb(205, 35, 35, 33));
        canvas.drawCircle(cx, cy, radius * 0.91f, fill);

        if (highlighted || pressed) {
            stroke.setStrokeWidth(Math.max(2.5f, getHeight() * 0.0032f));
            stroke.setColor(highlighted
                ? Color.argb(235, 226, 235, 18)
                : Color.argb(210, 240, 240, 210));
            canvas.drawCircle(cx, cy, radius * 0.96f, stroke);
        }

        drawIcon(canvas, cx, cy, radius * 0.72f, icon);
    }

    private void drawIcon(Canvas canvas, float cx, float cy, float r, int icon) {
        stroke.setStrokeWidth(Math.max(2.0f, getHeight() * 0.0030f));
        stroke.setColor(Color.argb(245, 255, 255, 255));
        fill.setColor(Color.argb(245, 255, 255, 255));

        switch (icon) {
            case ICON_AIM:
                drawCrosshairIcon(canvas, cx, cy, r);
                break;

            case ICON_RELOAD_BULLETS:
                drawThreeCartridges(canvas, cx, cy, r);
                break;

            case ICON_BULLET:
                drawBullet(canvas, cx, cy, r * 1.02f, -38.0f);
                break;

            case ICON_AIM_FIRE:
                drawCrosshairIcon(canvas, cx - r * 0.10f, cy - r * 0.04f, r * 0.72f);
                drawBullet(canvas, cx + r * 0.30f, cy + r * 0.30f, r * 0.52f, -38.0f);
                break;

            case ICON_RUN:
                drawRunner(canvas, cx, cy, r);
                break;

            case ICON_CROUCH:
                drawCrouchedShooter(canvas, cx, cy, r);
                break;

            case ICON_WEAPON:
                drawLongGun(canvas, cx, cy, r);
                break;

            case ICON_SWITCH:
                drawSwitch(canvas, cx, cy, r);
                break;

            case ICON_GRENADE:
                drawGrenade(canvas, cx, cy, r);
                break;

            default:
                break;
        }
    }

    private void drawCrosshairIcon(Canvas canvas, float cx, float cy, float r) {
        stroke.setStrokeWidth(Math.max(2.0f, getHeight() * 0.0028f));
        canvas.drawCircle(cx, cy, r * 0.42f, stroke);

        canvas.drawLine(cx - r * 0.78f, cy, cx - r * 0.26f, cy, stroke);
        canvas.drawLine(cx + r * 0.26f, cy, cx + r * 0.78f, cy, stroke);
        canvas.drawLine(cx, cy - r * 0.78f, cx, cy - r * 0.26f, stroke);
        canvas.drawLine(cx, cy + r * 0.26f, cx, cy + r * 0.78f, stroke);

        canvas.drawCircle(cx, cy, Math.max(2.2f, r * 0.07f), fill);
    }

    private void drawThreeCartridges(Canvas canvas, float cx, float cy, float r) {
        final float spacing = r * 0.34f;
        for (int i = -1; i <= 1; ++i) {
            drawBullet(canvas, cx + i * spacing, cy, r * 0.58f, -18.0f);
        }
    }

    private void drawBullet(Canvas canvas, float cx, float cy, float length, float degrees) {
        canvas.save();
        canvas.rotate(degrees, cx, cy);

        final float w = length * 0.27f;
        final float h = length;
        final float left = cx - w * 0.5f;
        final float top = cy - h * 0.5f;

        final RectF body = new RectF(
            left,
            top + h * 0.22f,
            left + w,
            top + h * 0.86f
        );
        canvas.drawRoundRect(body, w * 0.30f, w * 0.30f, fill);

        path.reset();
        path.moveTo(cx, top);
        path.lineTo(left + w, top + h * 0.25f);
        path.lineTo(left, top + h * 0.25f);
        path.close();
        canvas.drawPath(path, fill);

        canvas.drawRect(left - w * 0.06f, top + h * 0.82f,
            left + w * 1.06f, top + h, fill);

        canvas.restore();
    }

    private void drawRunner(Canvas canvas, float cx, float cy, float r) {
        final float headR = r * 0.13f;
        canvas.drawCircle(cx - r * 0.18f, cy - r * 0.48f, headR, fill);

        stroke.setStrokeWidth(Math.max(3.0f, r * 0.10f));
        canvas.drawLine(cx - r * 0.12f, cy - r * 0.30f,
            cx + r * 0.05f, cy + r * 0.05f, stroke);
        canvas.drawLine(cx - r * 0.02f, cy - r * 0.16f,
            cx + r * 0.42f, cy - r * 0.05f, stroke);
        canvas.drawLine(cx + r * 0.02f, cy + r * 0.02f,
            cx + r * 0.42f, cy + r * 0.42f, stroke);
        canvas.drawLine(cx + r * 0.02f, cy + r * 0.02f,
            cx - r * 0.38f, cy + r * 0.30f, stroke);
    }

    private void drawCrouchedShooter(Canvas canvas, float cx, float cy, float r) {
        canvas.drawCircle(cx - r * 0.24f, cy - r * 0.35f, r * 0.12f, fill);

        stroke.setStrokeWidth(Math.max(3.0f, r * 0.10f));
        canvas.drawLine(cx - r * 0.17f, cy - r * 0.20f,
            cx - r * 0.02f, cy + r * 0.16f, stroke);
        canvas.drawLine(cx - r * 0.02f, cy + r * 0.16f,
            cx + r * 0.32f, cy + r * 0.34f, stroke);
        canvas.drawLine(cx - r * 0.02f, cy + r * 0.16f,
            cx - r * 0.35f, cy + r * 0.40f, stroke);

        stroke.setStrokeWidth(Math.max(2.0f, r * 0.07f));
        canvas.drawLine(cx - r * 0.08f, cy - r * 0.12f,
            cx + r * 0.48f, cy - r * 0.18f, stroke);
        canvas.drawLine(cx + r * 0.08f, cy - r * 0.22f,
            cx + r * 0.48f, cy - r * 0.18f, stroke);
    }

    private void drawLongGun(Canvas canvas, float cx, float cy, float r) {
        canvas.save();
        canvas.rotate(-28.0f, cx, cy);

        stroke.setStrokeWidth(Math.max(4.0f, r * 0.12f));
        canvas.drawLine(cx - r * 0.72f, cy, cx + r * 0.62f, cy, stroke);

        fill.setColor(WHITE);
        path.reset();
        path.moveTo(cx - r * 0.65f, cy - r * 0.04f);
        path.lineTo(cx - r * 0.40f, cy - r * 0.18f);
        path.lineTo(cx - r * 0.24f, cy + r * 0.12f);
        path.lineTo(cx - r * 0.56f, cy + r * 0.18f);
        path.close();
        canvas.drawPath(path, fill);

        canvas.drawRect(cx + r * 0.10f, cy - r * 0.10f,
            cx + r * 0.65f, cy + r * 0.08f, fill);

        path.reset();
        path.moveTo(cx - r * 0.05f, cy + r * 0.02f);
        path.lineTo(cx + r * 0.12f, cy + r * 0.42f);
        path.lineTo(cx + r * 0.28f, cy + r * 0.38f);
        path.lineTo(cx + r * 0.16f, cy + r * 0.02f);
        path.close();
        canvas.drawPath(path, fill);

        canvas.restore();
    }

    private void drawSwitch(Canvas canvas, float cx, float cy, float r) {
        stroke.setStrokeWidth(Math.max(2.4f, r * 0.08f));

        final RectF topArc = new RectF(
            cx - r * 0.58f, cy - r * 0.52f,
            cx + r * 0.58f, cy + r * 0.28f
        );
        canvas.drawArc(topArc, 205.0f, 205.0f, false, stroke);

        path.reset();
        path.moveTo(cx + r * 0.46f, cy - r * 0.36f);
        path.lineTo(cx + r * 0.70f, cy - r * 0.28f);
        path.lineTo(cx + r * 0.52f, cy - r * 0.08f);
        path.close();
        canvas.drawPath(path, fill);

        final RectF bottomArc = new RectF(
            cx - r * 0.58f, cy - r * 0.22f,
            cx + r * 0.58f, cy + r * 0.58f
        );
        canvas.drawArc(bottomArc, 25.0f, 205.0f, false, stroke);

        path.reset();
        path.moveTo(cx - r * 0.46f, cy + r * 0.36f);
        path.lineTo(cx - r * 0.70f, cy + r * 0.28f);
        path.lineTo(cx - r * 0.52f, cy + r * 0.08f);
        path.close();
        canvas.drawPath(path, fill);
    }

    private void drawGrenade(Canvas canvas, float cx, float cy, float r) {
        canvas.drawCircle(cx, cy + r * 0.10f, r * 0.36f, stroke);
        canvas.drawRect(cx - r * 0.16f, cy - r * 0.34f,
            cx + r * 0.16f, cy - r * 0.16f, fill);
        canvas.drawLine(cx + r * 0.05f, cy - r * 0.32f,
            cx + r * 0.42f, cy - r * 0.48f, stroke);
    }

    private void drawPause(Canvas canvas) {
        final float cx = getWidth() * 0.962f;
        final float cy = getHeight() * 0.080f;
        final float r = getHeight() * 0.038f;

        fill.setColor(Color.argb(pausePressed ? 190 : 135, 42, 42, 42));
        canvas.drawCircle(cx, cy, r, fill);
        stroke.setStrokeWidth(Math.max(1.5f, getHeight() * 0.0016f));
        stroke.setColor(Color.argb(100, 180, 180, 180));
        canvas.drawCircle(cx, cy, r, stroke);

        fill.setColor(WHITE);
        final float barW = r * 0.16f;
        final float barH = r * 0.62f;
        canvas.drawRoundRect(
            new RectF(cx - r * 0.28f, cy - barH * 0.5f,
                cx - r * 0.28f + barW, cy + barH * 0.5f),
            barW * 0.3f, barW * 0.3f, fill);
        canvas.drawRoundRect(
            new RectF(cx + r * 0.12f, cy - barH * 0.5f,
                cx + r * 0.12f + barW, cy + barH * 0.5f),
            barW * 0.3f, barW * 0.3f, fill);
    }

    private void drawWorldCrosshair(Canvas canvas) {
        final float cx = getWidth() * 0.5f;
        final float cy = getHeight() * 0.5f;
        final float gap = getHeight() * 0.0075f;
        final float len = getHeight() * 0.013f;

        stroke.setStrokeWidth(Math.max(1.5f, getHeight() * 0.0017f));
        stroke.setColor(Color.argb(210, 255, 255, 255));

        canvas.drawLine(cx - gap - len, cy, cx - gap, cy, stroke);
        canvas.drawLine(cx + gap, cy, cx + gap + len, cy, stroke);
        canvas.drawLine(cx, cy - gap - len, cx, cy - gap, stroke);
        canvas.drawLine(cx, cy + gap, cx, cy + gap + len, stroke);
    }
}

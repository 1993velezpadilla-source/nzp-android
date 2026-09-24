#pragma once

namespace iw4native::android {

bool rendererInit();
void rendererResize(int width, int height);
void rendererFrame(float moveX,
                   float moveY,
                   float lookDeltaX,
                   float lookDeltaY,
                   bool firePressed,
                   bool adsPressed,
                   bool jumpPressed);
void rendererShutdown();

} // namespace iw4native::android

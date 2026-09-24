#pragma once

#include <cstddef>
#include <cstdint>

namespace iw4native::android {

bool rendererInit();
bool rendererLoadSanctum(const std::byte* data, std::size_t size);
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

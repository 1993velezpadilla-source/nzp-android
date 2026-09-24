#pragma once

#include <cstddef>
#include <cstdint>
#include <string>

namespace iw4native::android {

bool rendererInit();
bool rendererLoadSanctum(const std::byte* data, std::size_t size);
std::string rendererDiagnostic();
void rendererResize(int width, int height);
void rendererFrame(float moveX,
                   float moveY,
                   float lookDeltaX,
                   float lookDeltaY,
                   bool firePressed,
                   bool adsPressed,
                   bool jumpPressed,
                   bool reloadPressed,
                   bool usePressed,
                   bool knifePressed,
                   bool grenadePressed,
                   bool slidePressed,
                   bool pausePressed);
void rendererShutdown();

} // namespace iw4native::android

#pragma once

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <vector>

namespace iw4native {

struct PreviewVertex {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    float r = 1.0f;
    float g = 1.0f;
    float b = 1.0f;
};

struct PreviewBounds {
    float minX = 0.0f;
    float minY = 0.0f;
    float minZ = 0.0f;
    float maxX = 0.0f;
    float maxY = 0.0f;
    float maxZ = 0.0f;
};

bool decodeSanctumPreview(std::span<const std::byte> bytes,
                          std::vector<PreviewVertex>& vertices,
                          PreviewBounds& bounds,
                          std::string* errorMessage = nullptr);

} // namespace iw4native

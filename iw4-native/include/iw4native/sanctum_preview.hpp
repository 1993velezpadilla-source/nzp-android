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
    float nx = 0.0f;
    float ny = 1.0f;
    float nz = 0.0f;
};

struct PreviewBounds {
    float minX = 0.0f;
    float minY = 0.0f;
    float minZ = 0.0f;
    float maxX = 0.0f;
    float maxY = 0.0f;
    float maxZ = 0.0f;
};

struct PreviewSceneInfo {
    PreviewBounds bounds;
    float spawnX = 0.0f;
    float spawnY = 0.0f;
    float spawnZ = 0.0f;
    float lookX = 0.0f;
    float lookY = 0.0f;
    float lookZ = 0.0f;
};

bool decodeSanctumPreview(std::span<const std::byte> bytes,
                          std::vector<PreviewVertex>& vertices,
                          PreviewSceneInfo& scene,
                          std::string* errorMessage = nullptr);

} // namespace iw4native

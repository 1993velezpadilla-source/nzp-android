#include "iw4native/sanctum_preview.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>

namespace iw4native {
namespace {

constexpr std::size_t kHeaderBytes = 60;
constexpr std::size_t kTriangleRecordBytes = 20;
constexpr std::uint32_t kVersion = 2;
constexpr std::uint32_t kMaxTriangles = 1'000'000;

std::uint16_t readU16(const std::byte* p) {
    return static_cast<std::uint16_t>(
        static_cast<std::uint16_t>(std::to_integer<std::uint8_t>(p[0])) |
        (static_cast<std::uint16_t>(std::to_integer<std::uint8_t>(p[1])) << 8));
}

std::uint32_t readU32(const std::byte* p) {
    return
        static_cast<std::uint32_t>(std::to_integer<std::uint8_t>(p[0])) |
        (static_cast<std::uint32_t>(std::to_integer<std::uint8_t>(p[1])) << 8) |
        (static_cast<std::uint32_t>(std::to_integer<std::uint8_t>(p[2])) << 16) |
        (static_cast<std::uint32_t>(std::to_integer<std::uint8_t>(p[3])) << 24);
}

float readF32(const std::byte* p) {
    const std::uint32_t bits = readU32(p);
    float value = 0.0f;
    static_assert(sizeof(value) == sizeof(bits));
    std::memcpy(&value, &bits, sizeof(value));
    return value;
}

void setError(std::string* destination, const char* message) {
    if (destination) *destination = message;
}

float decodeAxis(std::uint16_t q, float minValue, float maxValue) {
    const float t = static_cast<float>(q) / 65535.0f;
    return minValue + (maxValue - minValue) * t;
}

bool finite(float value) {
    return std::isfinite(value);
}

bool nearBounds(float value, float minValue, float maxValue, float margin) {
    return value >= minValue - margin && value <= maxValue + margin;
}

} // namespace

bool decodeSanctumPreview(std::span<const std::byte> bytes,
                          std::vector<PreviewVertex>& vertices,
                          PreviewSceneInfo& scene,
                          std::string* errorMessage) {
    vertices.clear();
    scene = {};

    if (bytes.size() < kHeaderBytes) {
        setError(errorMessage, "SNP1 preview is truncated");
        return false;
    }

    if (std::to_integer<char>(bytes[0]) != 'S' ||
        std::to_integer<char>(bytes[1]) != 'N' ||
        std::to_integer<char>(bytes[2]) != 'P' ||
        std::to_integer<char>(bytes[3]) != '1') {
        setError(errorMessage, "SNP1 preview has invalid magic");
        return false;
    }

    const std::uint32_t version = readU32(bytes.data() + 4);
    if (version != kVersion) {
        setError(errorMessage, "SNP1 preview has unsupported version");
        return false;
    }

    const std::uint32_t triangleCount = readU32(bytes.data() + 8);
    if (triangleCount == 0 || triangleCount > kMaxTriangles) {
        setError(errorMessage, "SNP1 preview triangle count is invalid");
        return false;
    }

    const std::size_t expected =
        kHeaderBytes + static_cast<std::size_t>(triangleCount) * kTriangleRecordBytes;
    if (bytes.size() != expected) {
        setError(errorMessage, "SNP1 preview byte size does not match triangle count");
        return false;
    }

    auto& bounds = scene.bounds;
    bounds.minX = readF32(bytes.data() + 12);
    bounds.minY = readF32(bytes.data() + 16);
    bounds.minZ = readF32(bytes.data() + 20);
    bounds.maxX = readF32(bytes.data() + 24);
    bounds.maxY = readF32(bytes.data() + 28);
    bounds.maxZ = readF32(bytes.data() + 32);

    scene.spawnX = readF32(bytes.data() + 36);
    scene.spawnY = readF32(bytes.data() + 40);
    scene.spawnZ = readF32(bytes.data() + 44);
    scene.lookX = readF32(bytes.data() + 48);
    scene.lookY = readF32(bytes.data() + 52);
    scene.lookZ = readF32(bytes.data() + 56);

    const float values[] = {
        bounds.minX, bounds.minY, bounds.minZ,
        bounds.maxX, bounds.maxY, bounds.maxZ,
        scene.spawnX, scene.spawnY, scene.spawnZ,
        scene.lookX, scene.lookY, scene.lookZ
    };
    for (const float value : values) {
        if (!finite(value)) {
            setError(errorMessage, "SNP1 preview contains non-finite scene metadata");
            return false;
        }
    }

    if (!(bounds.maxX > bounds.minX) ||
        !(bounds.maxY > bounds.minY) ||
        !(bounds.maxZ > bounds.minZ)) {
        setError(errorMessage, "SNP1 preview bounds are degenerate");
        return false;
    }

    const float horizontalMargin =
        std::max(bounds.maxX - bounds.minX, bounds.maxZ - bounds.minZ) * 0.10f + 1.0f;
    const float verticalMargin = (bounds.maxY - bounds.minY) * 0.10f + 2.0f;

    if (!nearBounds(scene.spawnX, bounds.minX, bounds.maxX, horizontalMargin) ||
        !nearBounds(scene.spawnZ, bounds.minZ, bounds.maxZ, horizontalMargin) ||
        !nearBounds(scene.spawnY, bounds.minY, bounds.maxY, verticalMargin)) {
        setError(errorMessage, "SNP1 preview spawn is outside sane map bounds");
        return false;
    }

    if (!nearBounds(scene.lookX, bounds.minX, bounds.maxX, horizontalMargin) ||
        !nearBounds(scene.lookZ, bounds.minZ, bounds.maxZ, horizontalMargin) ||
        !nearBounds(scene.lookY, bounds.minY, bounds.maxY, verticalMargin)) {
        setError(errorMessage, "SNP1 preview look target is outside sane map bounds");
        return false;
    }

    vertices.reserve(static_cast<std::size_t>(triangleCount) * 3);
    const std::byte* cursor = bytes.data() + kHeaderBytes;

    for (std::uint32_t triangle = 0; triangle < triangleCount; ++triangle) {
        std::uint16_t q[9];
        for (int i = 0; i < 9; ++i) {
            q[i] = readU16(cursor + static_cast<std::size_t>(i) * 2);
        }
        const std::uint16_t rgb565 = readU16(cursor + 18);

        const float red =
            static_cast<float>((rgb565 >> 11) & 31) / 31.0f;
        const float green =
            static_cast<float>((rgb565 >> 5) & 63) / 63.0f;
        const float blue =
            static_cast<float>(rgb565 & 31) / 31.0f;

        float px[3]{};
        float py[3]{};
        float pz[3]{};
        for (int vertex = 0; vertex < 3; ++vertex) {
            const int base = vertex * 3;
            px[vertex] = decodeAxis(q[base + 0], bounds.minX, bounds.maxX);
            py[vertex] = decodeAxis(q[base + 1], bounds.minY, bounds.maxY);
            pz[vertex] = decodeAxis(q[base + 2], bounds.minZ, bounds.maxZ);
        }

        const float e1x = px[1] - px[0];
        const float e1y = py[1] - py[0];
        const float e1z = pz[1] - pz[0];
        const float e2x = px[2] - px[0];
        const float e2y = py[2] - py[0];
        const float e2z = pz[2] - pz[0];

        float nx = e1y * e2z - e1z * e2y;
        float ny = e1z * e2x - e1x * e2z;
        float nz = e1x * e2y - e1y * e2x;
        const float normalLength = std::sqrt(nx * nx + ny * ny + nz * nz);
        if (normalLength > 1.0e-8f) {
            nx /= normalLength;
            ny /= normalLength;
            nz /= normalLength;
        } else {
            nx = 0.0f;
            ny = 1.0f;
            nz = 0.0f;
        }

        for (int vertex = 0; vertex < 3; ++vertex) {
            vertices.push_back({
                px[vertex],
                py[vertex],
                pz[vertex],
                red,
                green,
                blue,
                nx,
                ny,
                nz
            });
        }

        cursor += kTriangleRecordBytes;
    }

    if (errorMessage) errorMessage->clear();
    return true;
}

} // namespace iw4native

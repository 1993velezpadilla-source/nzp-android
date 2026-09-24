#include "iw4native/virtual_filesystem.hpp"

#include <fstream>

namespace iw4native {

VirtualFileSystem::VirtualFileSystem(std::filesystem::path root)
    : root_(std::filesystem::weakly_canonical(std::move(root))) {}

std::optional<std::filesystem::path>
VirtualFileSystem::resolveSafe(const std::string& relativePath) const {
    if (relativePath.empty()) return std::nullopt;

    const std::filesystem::path rel(relativePath);
    if (rel.is_absolute()) return std::nullopt;

    for (const auto& component : rel) {
        if (component == "..") return std::nullopt;
    }

    const auto combined = (root_ / rel).lexically_normal();
    const auto rootText = root_.generic_string();
    const auto combinedText = combined.generic_string();

    if (combinedText.size() < rootText.size()) return std::nullopt;
    if (combinedText.compare(0, rootText.size(), rootText) != 0) return std::nullopt;

    return combined;
}

std::optional<std::vector<std::byte>>
VirtualFileSystem::readBinary(const std::string& relativePath) const {
    const auto path = resolveSafe(relativePath);
    if (!path || !std::filesystem::is_regular_file(*path)) return std::nullopt;

    std::ifstream stream(*path, std::ios::binary | std::ios::ate);
    if (!stream) return std::nullopt;

    const auto end = stream.tellg();
    if (end < 0) return std::nullopt;

    std::vector<std::byte> data(static_cast<std::size_t>(end));
    stream.seekg(0, std::ios::beg);

    if (!data.empty()) {
        stream.read(reinterpret_cast<char*>(data.data()),
                    static_cast<std::streamsize>(data.size()));
        if (!stream) return std::nullopt;
    }

    return data;
}

bool VirtualFileSystem::exists(const std::string& relativePath) const {
    const auto path = resolveSafe(relativePath);
    return path && std::filesystem::exists(*path);
}

const std::filesystem::path& VirtualFileSystem::root() const noexcept {
    return root_;
}

} // namespace iw4native

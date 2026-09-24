#pragma once

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <vector>

namespace iw4native {

class VirtualFileSystem {
public:
    explicit VirtualFileSystem(std::filesystem::path root);

    std::optional<std::vector<std::byte>> readBinary(const std::string& relativePath) const;
    bool exists(const std::string& relativePath) const;

    const std::filesystem::path& root() const noexcept;

private:
    std::optional<std::filesystem::path> resolveSafe(const std::string& relativePath) const;

    std::filesystem::path root_;
};

} // namespace iw4native

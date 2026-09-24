#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

namespace iw4native {

enum class AssetType : std::uint8_t {
    RawFile,
    Model,
    Animation,
    Material,
    Image,
    Weapon,
    World,
    Collision
};

struct AssetRecord {
    AssetType type = AssetType::RawFile;
    std::string name;
    std::vector<std::byte> payload;
};

class AssetDatabase {
public:
    bool insert(AssetRecord record);
    const AssetRecord* find(AssetType type, const std::string& name) const;
    bool contains(AssetType type, const std::string& name) const;
    std::size_t size() const noexcept;

private:
    static std::uint64_t makeKey(AssetType type, const std::string& name);
    std::unordered_map<std::uint64_t, AssetRecord> assets_;
};

} // namespace iw4native

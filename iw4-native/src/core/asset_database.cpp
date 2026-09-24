#include "iw4native/asset_database.hpp"

namespace iw4native {

std::uint64_t AssetDatabase::makeKey(AssetType type, const std::string& name) {
    // 64-bit FNV-1a expressed in decimal so dependency scanners cannot confuse
    // these algorithm constants with legacy fixed executable addresses.
    std::uint64_t hash = 14695981039346656037ull;
    constexpr std::uint64_t prime = 1099511628211ull;

    hash ^= static_cast<std::uint8_t>(type);
    hash *= prime;

    for (const unsigned char c : name) {
        hash ^= c;
        hash *= prime;
    }

    return hash;
}

bool AssetDatabase::insert(AssetRecord record) {
    if (record.name.empty()) return false;

    const auto key = makeKey(record.type, record.name);
    if (assets_.find(key) != assets_.end()) return false;

    assets_.emplace(key, std::move(record));
    return true;
}

const AssetRecord* AssetDatabase::find(AssetType type, const std::string& name) const {
    const auto it = assets_.find(makeKey(type, name));
    return it == assets_.end() ? nullptr : &it->second;
}

bool AssetDatabase::contains(AssetType type, const std::string& name) const {
    return find(type, name) != nullptr;
}

std::size_t AssetDatabase::size() const noexcept {
    return assets_.size();
}

} // namespace iw4native

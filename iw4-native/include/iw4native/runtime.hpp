#pragma once

#include <cstddef>
#include <cstdint>
#include <string>

namespace iw4native {

struct BootReport {
    bool ok = false;
    std::string platform;
    std::string mapName;
    std::uint64_t arenaBytes = 0;
    std::size_t dvarCount = 0;
    std::size_t assetCount = 0;
    std::size_t commandsExecuted = 0;
    std::string message;
};

BootReport bootStandalone(const std::string& platformName,
                          const std::string& mapName,
                          std::uint64_t arenaBytes);

} // namespace iw4native

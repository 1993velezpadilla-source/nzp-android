#include "iw4native/runtime.hpp"

#include "iw4native/asset_database.hpp"
#include "iw4native/command_buffer.hpp"
#include "iw4native/dvar.hpp"
#include "iw4native/memory_arena.hpp"

#include <cstddef>
#include <cstdint>
#include <vector>

namespace iw4native {

BootReport bootStandalone(const std::string& platformName,
                          const std::string& mapName,
                          std::uint64_t arenaBytes) {
    BootReport report;
    report.platform = platformName;
    report.mapName = mapName;
    report.arenaBytes = arenaBytes;

    if (platformName.empty()) {
        report.message = "platform name is required";
        return report;
    }

    if (mapName.empty()) {
        report.message = "map name is required";
        return report;
    }

    if (arenaBytes < 1024 * 1024) {
        report.message = "arena must be at least 1 MiB";
        return report;
    }

    MemoryArena arena(static_cast<std::size_t>(arenaBytes));
    auto* bootstrap = arena.allocate(4096, 64);
    if (!bootstrap) {
        report.message = "arena bootstrap allocation failed";
        return report;
    }

    DvarRegistry dvars;
    dvars.registerString("mapname", mapName);
    dvars.registerInt("com_maxfps", 60);
    dvars.registerInt("sv_running", 0);

    AssetDatabase assets;
    AssetRecord mapManifest;
    mapManifest.type = AssetType::RawFile;
    mapManifest.name = mapName + ".manifest";
    mapManifest.payload = {
        std::byte{1}, std::byte{0}, std::byte{0}, std::byte{0}
    };
    if (!assets.insert(std::move(mapManifest))) {
        report.message = "asset database bootstrap failed";
        return report;
    }

    CommandBuffer commands;
    commands.addCommand("map", [&](const std::vector<std::string>& args) {
        if (!args.empty()) dvars.setString("mapname", args.front());
    });
    commands.addCommand("setfps", [&](const std::vector<std::string>& args) {
        if (args.empty()) return;
        int value = 0;
        for (const char c : args.front()) {
            if (c < '0' || c > '9') return;
            value = value * 10 + (c - '0');
        }
        if (value > 0) dvars.setInt("com_maxfps", value);
    });
    commands.addCommand("startserver", [&](const std::vector<std::string>&) {
        dvars.setInt("sv_running", 1);
    });

    commands.enqueue("map " + mapName);
    commands.enqueue("setfps 60");
    commands.enqueue("startserver");

    report.commandsExecuted = commands.executeAll();
    report.dvarCount = dvars.size();
    report.assetCount = assets.size();

    const auto activeMap = dvars.getString("mapname");
    const auto maxFps = dvars.getInt("com_maxfps");
    const auto serverRunning = dvars.getInt("sv_running");

    if (!activeMap || *activeMap != mapName ||
        !maxFps || *maxFps != 60 ||
        !serverRunning || *serverRunning != 1 ||
        !assets.contains(AssetType::RawFile, mapName + ".manifest") ||
        report.commandsExecuted != 3 ||
        report.dvarCount != 3 ||
        report.assetCount != 1) {
        report.message = "standalone core self-check failed";
        return report;
    }

    report.ok = true;
    report.message = "standalone core initialized without original game executable";
    return report;
}

} // namespace iw4native

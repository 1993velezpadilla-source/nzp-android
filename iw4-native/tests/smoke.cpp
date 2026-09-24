#include "iw4native/asset_database.hpp"
#include "iw4native/command_buffer.hpp"
#include "iw4native/dvar.hpp"
#include "iw4native/memory_arena.hpp"
#include "iw4native/runtime.hpp"
#include "iw4native/virtual_filesystem.hpp"

#include <cassert>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

int main() {
    {
        iw4native::MemoryArena arena(1024);
        auto* a = arena.allocate(1, 64);
        auto* b = arena.allocate(32, 16);
        assert(a != nullptr);
        assert(b != nullptr);
        assert(reinterpret_cast<std::uintptr_t>(a) % 64 == 0);
        assert(reinterpret_cast<std::uintptr_t>(b) % 16 == 0);
        assert(arena.used() <= arena.capacity());
        arena.reset();
        assert(arena.used() == 0);
    }

    {
        iw4native::DvarRegistry dvars;
        dvars.registerString("mapname", "boot");
        dvars.registerInt("com_maxfps", 60);
        assert(dvars.size() == 2);
        assert(dvars.setString("mapname", "xziel_sanctum"));
        assert(dvars.getString("mapname").value() == "xziel_sanctum");
        assert(!dvars.setInt("mapname", 5));
    }

    {
        int called = 0;
        iw4native::CommandBuffer buffer;
        buffer.addCommand("ping", [&](const std::vector<std::string>& args) {
            assert(args.size() == 1);
            assert(args[0] == "pong");
            ++called;
        });
        buffer.enqueue("ping pong");
        assert(buffer.executeAll() == 1);
        assert(called == 1);
    }

    {
        iw4native::AssetDatabase assets;
        iw4native::AssetRecord record;
        record.type = iw4native::AssetType::World;
        record.name = "xziel_sanctum";
        record.payload = {std::byte{7}, std::byte{8}};
        assert(assets.insert(std::move(record)));
        assert(!assets.insert({iw4native::AssetType::World, "xziel_sanctum", {}}));
        assert(assets.contains(iw4native::AssetType::World, "xziel_sanctum"));
        assert(assets.find(iw4native::AssetType::World, "xziel_sanctum")->payload.size() == 2);
    }

    {
        const auto tempRoot = std::filesystem::temp_directory_path() / "iw4native-vfs-smoke";
        std::filesystem::remove_all(tempRoot);
        std::filesystem::create_directories(tempRoot / "maps");

        {
            std::ofstream out(tempRoot / "maps" / "sanctum.bin", std::ios::binary);
            out << "XZIEL";
        }

        iw4native::VirtualFileSystem vfs(tempRoot);
        assert(vfs.exists("maps/sanctum.bin"));
        assert(!vfs.exists("../escape.bin"));
        assert(!vfs.readBinary("../escape.bin"));

        const auto bytes = vfs.readBinary("maps/sanctum.bin");
        assert(bytes);
        assert(bytes->size() == 5);

        std::filesystem::remove_all(tempRoot);
    }

    {
        const auto report = iw4native::bootStandalone(
            "linux-test", "xziel_sanctum", 8ull * 1024ull * 1024ull);
        assert(report.ok);
        assert(report.mapName == "xziel_sanctum");
        assert(report.commandsExecuted == 3);
        assert(report.dvarCount == 3);
        assert(report.assetCount == 1);
        assert(report.message.find("standalone core initialized") != std::string::npos);
    }

    std::cout << "IW4 native standalone core smoke: PASS\n";
    return 0;
}

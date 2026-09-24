#include "iw4native/command_buffer.hpp"
#include "iw4native/dvar.hpp"
#include "iw4native/memory_arena.hpp"
#include "iw4native/runtime.hpp"

#include <cassert>
#include <cstdint>
#include <iostream>

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
        const auto report = iw4native::bootStandalone(
            "linux-test", "xziel_sanctum", 8ull * 1024ull * 1024ull);
        assert(report.ok);
        assert(report.mapName == "xziel_sanctum");
        assert(report.commandsExecuted == 3);
        assert(report.dvarCount == 3);
    }

    std::cout << "IW4 native standalone core smoke: PASS\n";
    return 0;
}

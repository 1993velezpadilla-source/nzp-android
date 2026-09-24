#include "iw4native/runtime.hpp"

#include <iostream>

int main(int argc, char** argv) {
    const std::string map = argc > 1 ? argv[1] : "xziel_sanctum";
    const auto report = iw4native::bootStandalone("linux-host", map, 32ull * 1024ull * 1024ull);

    std::cout
        << "iw4native.ok=" << (report.ok ? "true" : "false") << "\n"
        << "platform=" << report.platform << "\n"
        << "map=" << report.mapName << "\n"
        << "arenaBytes=" << report.arenaBytes << "\n"
        << "dvarCount=" << report.dvarCount << "\n"
        << "commandsExecuted=" << report.commandsExecuted << "\n"
        << "message=" << report.message << "\n";

    return report.ok ? 0 : 1;
}

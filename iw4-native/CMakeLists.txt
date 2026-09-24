cmake_minimum_required(VERSION 3.22)
project(iw4_native_research LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(IW4NATIVE_BUILD_TESTS "Build host-side tests" ON)

add_library(iw4native_core STATIC
    src/core/asset_database.cpp
    src/core/command_buffer.cpp
    src/core/dvar.cpp
    src/core/memory_arena.cpp
    src/core/runtime.cpp
    src/core/sanctum_preview.cpp
    src/core/virtual_filesystem.cpp
)

target_include_directories(iw4native_core PUBLIC include)
target_compile_definitions(iw4native_core PRIVATE IW4NATIVE_STANDALONE=1)
set_target_properties(iw4native_core PROPERTIES POSITION_INDEPENDENT_CODE ON)

if(ANDROID)
    add_library(iw4native SHARED
        src/android/android_probe.cpp
        src/android/gles_renderer.cpp
    )
    target_link_libraries(iw4native PRIVATE iw4native_core log android GLESv3)
    target_compile_definitions(iw4native PRIVATE IW4NATIVE_ANDROID=1)
else()
    add_executable(iw4native_host
        src/host/main.cpp
    )
    target_link_libraries(iw4native_host PRIVATE iw4native_core)

    if(IW4NATIVE_BUILD_TESTS)
        enable_testing()
        add_executable(iw4native_smoke tests/smoke.cpp)
        target_link_libraries(iw4native_smoke PRIVATE iw4native_core)
        add_test(NAME iw4native_smoke COMMAND iw4native_smoke)
    endif()
endif()

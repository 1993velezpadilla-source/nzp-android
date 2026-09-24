#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>

namespace iw4native {

class MemoryArena {
public:
    explicit MemoryArena(std::size_t bytes);

    void* allocate(std::size_t bytes, std::size_t alignment);
    void reset() noexcept;

    std::size_t capacity() const noexcept;
    std::size_t used() const noexcept;

private:
    std::unique_ptr<std::byte[]> storage_;
    std::size_t capacity_ = 0;
    std::size_t offset_ = 0;
};

} // namespace iw4native

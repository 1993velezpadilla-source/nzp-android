#include "iw4native/memory_arena.hpp"

#include <algorithm>
#include <cstdint>
#include <new>

namespace iw4native {

MemoryArena::MemoryArena(std::size_t bytes)
    : storage_(bytes ? std::make_unique<std::byte[]>(bytes) : nullptr),
      capacity_(bytes) {}

void* MemoryArena::allocate(std::size_t bytes, std::size_t alignment) {
    if (alignment == 0 || (alignment & (alignment - 1)) != 0) return nullptr;

    const auto base = reinterpret_cast<std::uintptr_t>(storage_.get());
    const auto current = base + offset_;
    const auto aligned = (current + (alignment - 1)) & ~(alignment - 1);
    const auto padding = static_cast<std::size_t>(aligned - current);

    if (padding > capacity_ - offset_) return nullptr;
    if (bytes > capacity_ - offset_ - padding) return nullptr;

    offset_ += padding + bytes;
    return reinterpret_cast<void*>(aligned);
}

void MemoryArena::reset() noexcept {
    offset_ = 0;
}

std::size_t MemoryArena::capacity() const noexcept {
    return capacity_;
}

std::size_t MemoryArena::used() const noexcept {
    return offset_;
}

} // namespace iw4native

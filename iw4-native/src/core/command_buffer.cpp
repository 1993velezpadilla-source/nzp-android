#include "iw4native/command_buffer.hpp"

#include <sstream>

namespace iw4native {

void CommandBuffer::addCommand(std::string name, Handler handler) {
    handlers_[std::move(name)] = std::move(handler);
}

void CommandBuffer::enqueue(std::string text) {
    pending_.push(std::move(text));
}

std::vector<std::string> CommandBuffer::tokenize(const std::string& text) {
    std::istringstream stream(text);
    std::vector<std::string> tokens;
    for (std::string token; stream >> token;) tokens.push_back(std::move(token));
    return tokens;
}

std::size_t CommandBuffer::executeAll() {
    std::size_t executed = 0;

    while (!pending_.empty()) {
        auto text = std::move(pending_.front());
        pending_.pop();

        auto tokens = tokenize(text);
        if (tokens.empty()) continue;

        const auto it = handlers_.find(tokens.front());
        if (it == handlers_.end()) continue;

        tokens.erase(tokens.begin());
        it->second(tokens);
        ++executed;
    }

    return executed;
}

} // namespace iw4native

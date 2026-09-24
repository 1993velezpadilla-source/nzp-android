#pragma once

#include <functional>
#include <queue>
#include <string>
#include <unordered_map>
#include <vector>

namespace iw4native {

class CommandBuffer {
public:
    using Handler = std::function<void(const std::vector<std::string>&)>;

    void addCommand(std::string name, Handler handler);
    void enqueue(std::string text);
    std::size_t executeAll();

private:
    static std::vector<std::string> tokenize(const std::string& text);

    std::unordered_map<std::string, Handler> handlers_;
    std::queue<std::string> pending_;
};

} // namespace iw4native

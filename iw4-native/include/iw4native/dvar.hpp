#pragma once

#include <optional>
#include <string>
#include <unordered_map>

namespace iw4native {

class DvarRegistry {
public:
    void registerString(std::string name, std::string value);
    void registerInt(std::string name, int value);

    bool setString(const std::string& name, std::string value);
    bool setInt(const std::string& name, int value);

    std::optional<std::string> getString(const std::string& name) const;
    std::optional<int> getInt(const std::string& name) const;

    std::size_t size() const noexcept;

private:
    struct Value {
        enum class Type { String, Int } type;
        std::string stringValue;
        int intValue = 0;
    };

    std::unordered_map<std::string, Value> values_;
};

} // namespace iw4native

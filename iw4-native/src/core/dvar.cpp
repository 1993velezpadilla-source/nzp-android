#include "iw4native/dvar.hpp"

namespace iw4native {

void DvarRegistry::registerString(std::string name, std::string value) {
    values_[std::move(name)] = Value{Value::Type::String, std::move(value), 0};
}

void DvarRegistry::registerInt(std::string name, int value) {
    values_[std::move(name)] = Value{Value::Type::Int, {}, value};
}

bool DvarRegistry::setString(const std::string& name, std::string value) {
    const auto it = values_.find(name);
    if (it == values_.end() || it->second.type != Value::Type::String) return false;
    it->second.stringValue = std::move(value);
    return true;
}

bool DvarRegistry::setInt(const std::string& name, int value) {
    const auto it = values_.find(name);
    if (it == values_.end() || it->second.type != Value::Type::Int) return false;
    it->second.intValue = value;
    return true;
}

std::optional<std::string> DvarRegistry::getString(const std::string& name) const {
    const auto it = values_.find(name);
    if (it == values_.end() || it->second.type != Value::Type::String) return std::nullopt;
    return it->second.stringValue;
}

std::optional<int> DvarRegistry::getInt(const std::string& name) const {
    const auto it = values_.find(name);
    if (it == values_.end() || it->second.type != Value::Type::Int) return std::nullopt;
    return it->second.intValue;
}

std::size_t DvarRegistry::size() const noexcept {
    return values_.size();
}

} // namespace iw4native

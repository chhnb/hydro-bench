#pragma once
#include <fstream>
#include <sstream>
#include <string>
#include <stdexcept>
#include <utility>

namespace io {

inline void AssertFileOpen(const std::ifstream& file, const std::string& filename) {
    if (!file.is_open()) {
        std::cerr << "ERROR: Cannot open file " << filename << std::endl;
        exit(1);
    }
}

template <typename T>
T readFromLine(const std::string& line) {
    std::istringstream iss(line);
    T result{};
    if (!(iss >> result)) {
        throw std::runtime_error("parse error: " + line);
    }
    return result;
}

inline void _readDataFromFile(std::ifstream& /*file_to_read*/) {}

template <typename T, typename... Args>
void _readDataFromFile(std::ifstream& file_to_read, T& first, Args&... args) {
    std::string current_line;
    if (!std::getline(file_to_read, current_line)) {
        throw std::runtime_error("unexpected EOF");
    }
    first = readFromLine<T>(current_line);
    _readDataFromFile(file_to_read, args...);
}

template <typename... Args>
void readData(const std::string& filePath, Args&... args) {
    std::ifstream file_to_read(filePath);
    if (!file_to_read.is_open()) {
        throw std::runtime_error("cannot open: " + filePath);
    }
    _readDataFromFile(file_to_read, args...);
}

} // namespace io
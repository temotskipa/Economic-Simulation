#include "io/config.h"

#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <string>

#include "data/constants.cuh"

namespace austrian_abm {

namespace {

const char* GetEnvFirst(const char* primary, const char* alias) {
    const char* raw = std::getenv(primary);
    if (raw && *raw) return raw;
    raw = std::getenv(alias);
    if (raw && *raw) return raw;
    return nullptr;
}

}  // namespace

std::string SanitizeEnvForLog(const char* raw) {
    if (!raw) return "";
    constexpr size_t kMaxLogLen = 128;
    std::string sanitized;
    sanitized.reserve(kMaxLogLen + 4);
    for (size_t i = 0; raw[i] != '\0'; ++i) {
        if (i >= kMaxLogLen) {
            sanitized += "...";
            break;
        }
        const unsigned char c = static_cast<unsigned char>(raw[i]);
        sanitized += std::isprint(c) ? static_cast<char>(c) : '?';
    }
    return sanitized;
}

unsigned int ParseUnsignedEnv(const char* name, const unsigned int default_value) {
    const char* raw = std::getenv(name);
    if (!raw || !*raw) return default_value;
    char* end = nullptr;
    const auto parsed = static_cast<std::uint64_t>(std::strtoull(raw, &end, 10));
    if (end == raw || *end != '\0' || parsed > std::numeric_limits<unsigned int>::max()) {
        std::printf("Ignoring invalid %s=%s, using %u\n",
            name, SanitizeEnvForLog(raw).c_str(), default_value);
        return default_value;
    }
    return static_cast<unsigned int>(parsed);
}

float ParseFloatEnv(const char* name, const float default_value) {
    const char* raw = std::getenv(name);
    if (!raw || !*raw) return default_value;
    char* end = nullptr;
    const float parsed = std::strtof(raw, &end);
    if (end == raw || *end != '\0') {
        std::printf("Ignoring invalid %s=%s, using %.3f\n",
            name, SanitizeEnvForLog(raw).c_str(), default_value);
        return default_value;
    }
    return parsed;
}

unsigned int ParseRandomSeedEnv() {
    const char* raw = GetEnvFirst("AUSTRIAN_ABM_SEED", "AUSTRIAN_ABM_RANDOM_SEED");
    if (!raw || !*raw) return kDefaultRandomSeed;
    char* end = nullptr;
    const auto parsed = static_cast<std::uint64_t>(std::strtoull(raw, &end, 10));
    if (end == raw || *end != '\0' || parsed > std::numeric_limits<unsigned int>::max()) {
        std::printf("Ignoring invalid seed=%s, using %u\n",
            SanitizeEnvForLog(raw).c_str(), kDefaultRandomSeed);
        return kDefaultRandomSeed;
    }
    return static_cast<unsigned int>(parsed);
}

std::filesystem::path ResolveReportDirectory() {
    const char* raw = std::getenv("AUSTRIAN_ABM_REPORT_DIR");
    if (raw && *raw) return std::filesystem::path(raw);
    return std::filesystem::path("reports");
}

}  // namespace austrian_abm
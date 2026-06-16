#pragma once

#include <filesystem>
#include <string>

namespace austrian_abm {

std::string SanitizeEnvForLog(const char* raw);

unsigned int ParseUnsignedEnv(const char* name, unsigned int default_value);
float ParseFloatEnv(const char* name, float default_value);
unsigned int ParseRandomSeedEnv();

std::filesystem::path ResolveReportDirectory();

}  // namespace austrian_abm
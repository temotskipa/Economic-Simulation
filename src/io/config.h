#pragma once

#include <array>
#include <filesystem>
#include <string>

#include "data/constants.cuh"

namespace austrian_abm {

struct SimulationConfig {
    unsigned int steps = 12u;
    unsigned int seed = 42u;
    unsigned int grid_width = 224u;
    unsigned int grid_height = 224u;
    float occupancy = 0.1f;
    float initial_money = 100.0f;
    unsigned int good_stages = 2u;
    float natural_rate = 0.08f;
    float policy_rate = 0.02f;
    unsigned int rate_shock_step = 6u;
    float trade_radius = kDefaultTradeRadius;
    std::array<float, kMaxRegions> region_productivity = {0.8f, 1.1f, 1.0f, 1.4f};
};

std::string SanitizeEnvForLog(const char* raw);

unsigned int ParseUnsignedEnv(const char* name, unsigned int default_value);
float ParseFloatEnv(const char* name, float default_value);
unsigned int ParseRandomSeedEnv();

SimulationConfig ParseSimulationConfig(int argc, const char** argv);
std::filesystem::path ResolveReportDirectory();

}  // namespace austrian_abm
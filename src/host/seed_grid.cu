#include <array>
#include <cmath>
#include <random>
#include <vector>

#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_INIT_FUNCTION(SeedGrid) {
    const unsigned int grid_width = FLAMEGPU->environment.getProperty<unsigned int>("GRID_WIDTH");
    const unsigned int grid_height = FLAMEGPU->environment.getProperty<unsigned int>("GRID_HEIGHT");
    const float occupancy = FLAMEGPU->environment.getProperty<float>("OCCUPANCY");
    const float initial_money = FLAMEGPU->environment.getProperty<float>("INITIAL_MONEY");
    const unsigned int seed = FLAMEGPU->environment.getProperty<unsigned int>("RANDOM_SEED");

    std::mt19937 rng(seed);
    std::uniform_real_distribution<float> u01(0.0f, 1.0f);
    std::uniform_int_distribution<int> agent_sugar_dist(0, kSugarMaxCapacity * 2);
    std::uniform_int_distribution<int> agent_spice_dist(0, kSpiceMaxCapacity * 2);
    std::uniform_int_distribution<int> poor_env_dist(0, kSugarMaxCapacity / 2);
    std::uniform_real_distribution<float> skill_dist(kMinProductionSkill, kMaxProductionSkill);
    std::uniform_real_distribution<float> time_pref_dist(kMinTimePreference, kMaxTimePreference);

    std::vector<std::array<unsigned int, 4>> hotspots;
    {
        std::uniform_int_distribution<unsigned int> width_dist(0, grid_width - 1u);
        std::uniform_int_distribution<unsigned int> height_dist(0, grid_height - 1u);
        std::uniform_int_distribution<unsigned int> radius_dist(5u, 30u);
        float hotspot_area = 0.0f;
        const float grid_area = static_cast<float>(grid_width) * static_cast<float>(grid_height);
        while (hotspot_area < grid_area) {
            hotspots.push_back({width_dist(rng), height_dist(rng), radius_dist(rng), kSugarMaxCapacity});
            hotspot_area += 3.141f * static_cast<float>(std::get<2>(hotspots.back()))
                * static_cast<float>(std::get<2>(hotspots.back()));
        }
    }

    flamegpu::HostAgentAPI cells = FLAMEGPU->agent("cell");
    unsigned int agent_id = 0u;
    for (unsigned int x = 0; x < grid_width; ++x) {
        for (unsigned int y = 0; y < grid_height; ++y) {
            flamegpu::HostNewAgentAPI instance = cells.newAgent();
            instance.setVariable<unsigned int, 2>("pos", {x, y});

            if (u01(rng) < occupancy) {
                instance.setVariable<int>("agent_id", static_cast<int>(agent_id++));
                instance.setVariable<int>("status", kAgentStatusOccupied);
                instance.setVariable<int>("sugar_level", agent_sugar_dist(rng) / 2);
                instance.setVariable<int>("spice_level", agent_spice_dist(rng) / 2);
                instance.setVariable<int>("metabolism", kDefaultMetabolism);
                instance.setVariable<float>("money", initial_money);
                instance.setVariable<int>("food_level", 0);
                instance.setVariable<float>("production_skill", skill_dist(rng));
                instance.setVariable<int>("activity_mode", kActivityHarvest);
                instance.setVariable<int>("step_production", 0);
                instance.setVariable<int>("capital_stock", 0);
                instance.setVariable<int>("intermediate_level", 0);
                instance.setVariable<float>("time_preference", time_pref_dist(rng));
                instance.setVariable<int>("production_stage", kProductionStageIdle);
                instance.setVariable<int>("stage_progress", 0);
                instance.setVariable<int>("is_capital_owner", 0);
                instance.setVariable<int>("step_investment", 0);
            } else {
                instance.setVariable<int>("agent_id", -1);
                instance.setVariable<int>("status", kAgentStatusUnoccupied);
                instance.setVariable<int>("sugar_level", 0);
                instance.setVariable<int>("spice_level", 0);
                instance.setVariable<int>("metabolism", 0);
                instance.setVariable<float>("money", 0.0f);
                instance.setVariable<int>("food_level", 0);
                instance.setVariable<float>("production_skill", 0.0f);
                instance.setVariable<int>("activity_mode", kActivityHarvest);
                instance.setVariable<int>("step_production", 0);
                instance.setVariable<int>("capital_stock", 0);
                instance.setVariable<int>("intermediate_level", 0);
                instance.setVariable<float>("time_preference", kMaxTimePreference);
                instance.setVariable<int>("production_stage", kProductionStageIdle);
                instance.setVariable<int>("stage_progress", 0);
                instance.setVariable<int>("is_capital_owner", 0);
                instance.setVariable<int>("step_investment", 0);
            }

            unsigned int env_sugar = 0u;
            unsigned int env_spice = 0u;
            constexpr int hotspot_core_size = 5;
            for (const auto& hs : hotspots) {
                const int hs_x = static_cast<int>(hs[0]);
                const int hs_y = static_cast<int>(hs[1]);
                const unsigned int hs_rad = hs[2];
                const unsigned int hs_level = hs[3];
                const float hs_dist = std::sqrt(
                    static_cast<float>((hs_x - static_cast<int>(x)) * (hs_x - static_cast<int>(x))
                        + (hs_y - static_cast<int>(y)) * (hs_y - static_cast<int>(y))));
                if (hs_dist <= hotspot_core_size) {
                    env_sugar = std::max(env_sugar, hs_level);
                    env_spice = std::max(env_spice, hs_level / 2u);
                } else if (hs_dist <= static_cast<float>(hs_rad)) {
                    const int non_core_len = static_cast<int>(hs_rad) - hotspot_core_size;
                    const float dist_from_core = hs_dist - static_cast<float>(hotspot_core_size);
                    const unsigned int t = static_cast<unsigned int>(
                        static_cast<float>(hs_level) * (static_cast<float>(non_core_len) - dist_from_core)
                        / static_cast<float>(non_core_len));
                    env_sugar = std::max(env_sugar, t);
                    env_spice = std::max(env_spice, t / 2u);
                }
            }
            if (env_sugar < kSugarMaxCapacity / 2u) env_sugar = static_cast<unsigned int>(poor_env_dist(rng));
            if (env_spice < kSpiceMaxCapacity / 2u) env_spice = static_cast<unsigned int>(poor_env_dist(rng) / 2);

            instance.setVariable<int>("env_max_sugar_level", static_cast<int>(env_sugar));
            instance.setVariable<int>("env_sugar_level", static_cast<int>(env_sugar));
            instance.setVariable<int>("env_max_spice_level", static_cast<int>(env_spice));
            instance.setVariable<int>("env_spice_level", static_cast<int>(env_spice));
            instance.setVariable<float>("sugar_bid", 0.0f);
            instance.setVariable<float>("sugar_ask", 0.0f);
            instance.setVariable<float>("spice_bid", 0.0f);
            instance.setVariable<float>("spice_ask", 0.0f);
        }
    }

    FLAMEGPU->environment.setProperty<unsigned int>("AGENT_COUNT", agent_id);
}

}  // namespace austrian_abm
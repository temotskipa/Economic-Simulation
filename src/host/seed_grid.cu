#include <array>
#include <cmath>
#include <random>
#include <vector>

#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "data/goods_catalog.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

namespace {

unsigned int ComputePatchLevel(
    const unsigned int x,
    const unsigned int y,
    const std::vector<std::array<unsigned int, 4>>& hotspots,
    const unsigned int fallback_level) {
    unsigned int level = 0u;
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
            level = std::max(level, hs_level);
        } else if (hs_dist <= static_cast<float>(hs_rad)) {
            const int non_core_len = static_cast<int>(hs_rad) - hotspot_core_size;
            const float dist_from_core = hs_dist - static_cast<float>(hotspot_core_size);
            const unsigned int t = static_cast<unsigned int>(
                static_cast<float>(hs_level) * (static_cast<float>(non_core_len) - dist_from_core)
                / static_cast<float>(non_core_len));
            level = std::max(level, t);
        }
    }
    return level > 0u ? level : fallback_level;
}

void InitInventoryZeros(flamegpu::HostNewAgentAPI& instance) {
    for (int good = 0; good < kGoodCount; ++good) {
        instance.setVariable<int, kGoodCount>("inventory", good, 0);
        instance.setVariable<float, kGoodCount>("bid_price", good, 0.0f);
        instance.setVariable<float, kGoodCount>("ask_price", good, 0.0f);
    }
}

}  // namespace

FLAMEGPU_INIT_FUNCTION(SeedGrid) {
    const unsigned int grid_width = FLAMEGPU->environment.getProperty<unsigned int>("GRID_WIDTH");
    const unsigned int grid_height = FLAMEGPU->environment.getProperty<unsigned int>("GRID_HEIGHT");
    const float occupancy = FLAMEGPU->environment.getProperty<float>("OCCUPANCY");
    const float initial_money = FLAMEGPU->environment.getProperty<float>("INITIAL_MONEY");
    const unsigned int seed = FLAMEGPU->environment.getProperty<unsigned int>("RANDOM_SEED");

    std::mt19937 rng(seed);
    std::uniform_real_distribution<float> u01(0.0f, 1.0f);
    std::uniform_int_distribution<int> agent_grain_dist(0, kSugarMaxCapacity * 2);
    std::uniform_int_distribution<int> agent_fruit_dist(0, kSpiceMaxCapacity * 2);
    std::uniform_int_distribution<int> poor_env_dist(0, kSugarMaxCapacity / 2);
    std::uniform_int_distribution<int> poor_iron_dist(0, kIronMaxCapacity / 2);
    std::uniform_int_distribution<int> poor_coal_dist(0, kCoalMaxCapacity / 2);
    std::uniform_real_distribution<float> skill_dist(kMinProductionSkill, kMaxProductionSkill);
    std::uniform_real_distribution<float> time_pref_dist(kMinTimePreference, kMaxTimePreference);

    const float grid_area = static_cast<float>(grid_width) * static_cast<float>(grid_height);

    std::vector<std::array<unsigned int, 4>> grain_hotspots;
    {
        std::uniform_int_distribution<unsigned int> width_dist(0, grid_width - 1u);
        std::uniform_int_distribution<unsigned int> height_dist(0, grid_height - 1u);
        std::uniform_int_distribution<unsigned int> radius_dist(5u, 30u);
        float hotspot_area = 0.0f;
        while (hotspot_area < grid_area) {
            grain_hotspots.push_back({width_dist(rng), height_dist(rng), radius_dist(rng), kSugarMaxCapacity});
            hotspot_area += 3.141f * static_cast<float>(std::get<2>(grain_hotspots.back()))
                * static_cast<float>(std::get<2>(grain_hotspots.back()));
        }
    }

    std::vector<std::array<unsigned int, 4>> fruit_hotspots;
    for (const auto& hs : grain_hotspots) {
        fruit_hotspots.push_back({hs[0], hs[1], hs[2], kSpiceMaxCapacity});
    }

    auto make_resource_hotspots = [&](const unsigned int max_capacity, const float area_fraction) {
        std::vector<std::array<unsigned int, 4>> hotspots;
        std::uniform_int_distribution<unsigned int> width_dist(0, grid_width - 1u);
        std::uniform_int_distribution<unsigned int> height_dist(0, grid_height - 1u);
        std::uniform_int_distribution<unsigned int> radius_dist(4u, 18u);
        float hotspot_area = 0.0f;
        const float target_area = grid_area * area_fraction;
        while (hotspot_area < target_area) {
            hotspots.push_back({width_dist(rng), height_dist(rng), radius_dist(rng), max_capacity});
            hotspot_area += 3.141f * static_cast<float>(std::get<2>(hotspots.back()))
                * static_cast<float>(std::get<2>(hotspots.back()));
        }
        return hotspots;
    };

    const auto iron_hotspots = make_resource_hotspots(kIronMaxCapacity, 0.12f);
    const auto coal_hotspots = make_resource_hotspots(kCoalMaxCapacity, 0.10f);

    flamegpu::HostAgentAPI cells = FLAMEGPU->agent("cell");
    unsigned int agent_id = 0u;
    for (unsigned int x = 0; x < grid_width; ++x) {
        for (unsigned int y = 0; y < grid_height; ++y) {
            flamegpu::HostNewAgentAPI instance = cells.newAgent();
            instance.setVariable<unsigned int, 2>("pos", {x, y});
            InitInventoryZeros(instance);

            if (u01(rng) < occupancy) {
                instance.setVariable<int>("agent_id", static_cast<int>(agent_id++));
                instance.setVariable<int>("status", kAgentStatusOccupied);
                instance.setVariable<int, kGoodCount>("inventory", kGoodGrain, agent_grain_dist(rng) / 2);
                instance.setVariable<int, kGoodCount>("inventory", kGoodFruit, agent_fruit_dist(rng) / 2);
                instance.setVariable<int>("metabolism", kDefaultMetabolism);
                instance.setVariable<float>("money", initial_money);
                instance.setVariable<float>("production_skill", skill_dist(rng));
                instance.setVariable<int>("activity_mode", kActivityHarvest);
                instance.setVariable<int>("step_production", 0);
                instance.setVariable<int>("capital_stock", 0);
                instance.setVariable<float>("time_preference", time_pref_dist(rng));
                instance.setVariable<int>("production_stage", kProductionStageIdle);
                instance.setVariable<int>("stage_progress", 0);
                instance.setVariable<int>("is_capital_owner", 0);
                instance.setVariable<int>("step_investment", 0);
                instance.setVariable<float>("loan_balance", 0.0f);
                instance.setVariable<float>("deposit_balance", 0.0f);
                instance.setVariable<float>("loan_rate", 0.0f);
                instance.setVariable<int>("step_loan", 0);
            } else {
                instance.setVariable<int>("agent_id", -1);
                instance.setVariable<int>("status", kAgentStatusUnoccupied);
                instance.setVariable<int>("metabolism", 0);
                instance.setVariable<float>("money", 0.0f);
                instance.setVariable<float>("production_skill", 0.0f);
                instance.setVariable<int>("activity_mode", kActivityHarvest);
                instance.setVariable<int>("step_production", 0);
                instance.setVariable<int>("capital_stock", 0);
                instance.setVariable<float>("time_preference", kMaxTimePreference);
                instance.setVariable<int>("production_stage", kProductionStageIdle);
                instance.setVariable<int>("stage_progress", 0);
                instance.setVariable<int>("is_capital_owner", 0);
                instance.setVariable<int>("step_investment", 0);
                instance.setVariable<float>("loan_balance", 0.0f);
                instance.setVariable<float>("deposit_balance", 0.0f);
                instance.setVariable<float>("loan_rate", 0.0f);
                instance.setVariable<int>("step_loan", 0);
            }

            unsigned int env_grain = ComputePatchLevel(x, y, grain_hotspots, 0u);
            unsigned int env_fruit = ComputePatchLevel(x, y, fruit_hotspots, 0u) / 2u;
            unsigned int env_iron = ComputePatchLevel(x, y, iron_hotspots, 0u);
            unsigned int env_coal = ComputePatchLevel(x, y, coal_hotspots, 0u);

            if (env_grain < kSugarMaxCapacity / 2u) {
                env_grain = static_cast<unsigned int>(poor_env_dist(rng));
            }
            if (env_fruit < kSpiceMaxCapacity / 2u) {
                env_fruit = static_cast<unsigned int>(poor_env_dist(rng) / 2);
            }
            if (env_iron < kIronMaxCapacity / 2u) {
                env_iron = static_cast<unsigned int>(poor_iron_dist(rng));
            }
            if (env_coal < kCoalMaxCapacity / 2u) {
                env_coal = static_cast<unsigned int>(poor_coal_dist(rng));
            }

            instance.setVariable<int>("env_max_sugar_level", static_cast<int>(env_grain));
            instance.setVariable<int>("env_sugar_level", static_cast<int>(env_grain));
            instance.setVariable<int>("env_max_spice_level", static_cast<int>(env_fruit));
            instance.setVariable<int>("env_spice_level", static_cast<int>(env_fruit));
            instance.setVariable<int>("env_max_iron_level", static_cast<int>(env_iron));
            instance.setVariable<int>("env_iron_level", static_cast<int>(env_iron));
            instance.setVariable<int>("env_max_coal_level", static_cast<int>(env_coal));
            instance.setVariable<int>("env_coal_level", static_cast<int>(env_coal));
        }
    }

    FLAMEGPU->environment.setProperty<unsigned int>("AGENT_COUNT", agent_id);
}

}  // namespace austrian_abm
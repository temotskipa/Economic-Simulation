#pragma once

#include "flamegpu/flamegpu.h"

#include <array>
#include <filesystem>
#include <string>
#include <unordered_map>

#include "data/goods_catalog.cuh"

namespace austrian_abm {

struct SimulationCatalog {
    unsigned int good_count = 0u;
    unsigned int recipe_count = 0u;
    unsigned int roundabout_recipe_count = 0u;
    int food_recipe_index = -1;
    int credit_min_grain = 1;
    int credit_min_fruit = 1;

    unsigned int goods_count = 0u;
    unsigned int services_count = 0u;

    std::array<int, kMaxGoods> kind{};
    std::array<int, kMaxGoods> category{};
    std::array<float, kMaxGoods> utility{};
    std::array<unsigned int, kMaxGoods> flags{};
    std::array<int, kMaxGoods> complement{};
    std::array<float, kMaxGoods> default_price{};
    std::array<int, kMaxGoods> decay_per_step{};

    std::array<int, kMaxRecipes> recipe_output_good{};
    std::array<int, kMaxRecipes> recipe_output_qty{};
    std::array<int, kMaxRecipes> recipe_input0_good{};
    std::array<int, kMaxRecipes> recipe_input0_qty{};
    std::array<int, kMaxRecipes> recipe_input1_good{};
    std::array<int, kMaxRecipes> recipe_input1_qty{};
    std::array<float, kMaxRecipes> recipe_min_skill{};
    std::array<int, kMaxRecipes> recipe_activity{};

    std::array<int, kMaxRoundaboutRecipes> roundabout_output_good{};
    std::array<int, kMaxRoundaboutRecipes> roundabout_output_qty{};
    std::array<int, kMaxRoundaboutRecipes> roundabout_input0_good{};
    std::array<int, kMaxRoundaboutRecipes> roundabout_input0_qty{};
    std::array<int, kMaxRoundaboutRecipes> roundabout_input1_good{};
    std::array<int, kMaxRoundaboutRecipes> roundabout_input1_qty{};

    std::unordered_map<std::string, int> good_index;
};

std::filesystem::path ResolveCatalogPath();
SimulationCatalog LoadSimulationCatalog(const std::filesystem::path& path);
void UploadCatalogToEnvironment(flamegpu::EnvironmentDescription& env, const SimulationCatalog& catalog);

float CatalogUtility(const SimulationCatalog& catalog, const int good);

}  // namespace austrian_abm
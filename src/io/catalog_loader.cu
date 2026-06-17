#include "io/catalog.h"

#include <algorithm>
#include <cstdio>
#include <fstream>
#include <stdexcept>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

#include "data/constants.cuh"
#include "io/config.h"

namespace austrian_abm {

namespace {

int ParseCategory(const std::string& value) {
    if (value == "RES") return kCategoryRes;
    if (value == "STAPLE") return kCategoryStaple;
    if (value == "IND") return kCategoryIndustrial;
    if (value == "TECH") return kCategoryTech;
    throw std::runtime_error("Unknown good category: " + value);
}

int ParseActivity(const std::string& value) {
    if (value == "any") return kRecipeAnyActivity;
    if (value == "produce") return kActivityProduce;
    if (value == "roundabout") return kActivityRoundabout;
    throw std::runtime_error("Unknown recipe activity: " + value);
}

int ResolveGoodIndex(const SimulationCatalog& catalog, const std::string& id) {
    const auto it = catalog.good_index.find(id);
    if (it == catalog.good_index.end()) {
        throw std::runtime_error("Unknown good id in catalog: " + id);
    }
    return it->second;
}

void ParseRecipeInputs(
    const nlohmann::json& inputs,
    SimulationCatalog& catalog,
    const int recipe_index) {
    catalog.recipe_input0_good[recipe_index] = kNoRecipeInput;
    catalog.recipe_input0_qty[recipe_index] = 0;
    catalog.recipe_input1_good[recipe_index] = kNoRecipeInput;
    catalog.recipe_input1_qty[recipe_index] = 0;
    if (!inputs.is_array()) return;
    if (inputs.size() > 0u) {
        catalog.recipe_input0_good[recipe_index] =
            ResolveGoodIndex(catalog, inputs[0].at("good").get<std::string>());
        catalog.recipe_input0_qty[recipe_index] = inputs[0].at("qty").get<int>();
    }
    if (inputs.size() > 1u) {
        catalog.recipe_input1_good[recipe_index] =
            ResolveGoodIndex(catalog, inputs[1].at("good").get<std::string>());
        catalog.recipe_input1_qty[recipe_index] = inputs[1].at("qty").get<int>();
    }
    if (inputs.size() > 2u) {
        throw std::runtime_error("Recipes support at most two inputs");
    }
}

void ParseRoundaboutInputs(
    const nlohmann::json& inputs,
    SimulationCatalog& catalog,
    const int recipe_index) {
    catalog.roundabout_input0_good[recipe_index] = kNoRecipeInput;
    catalog.roundabout_input0_qty[recipe_index] = 0;
    catalog.roundabout_input1_good[recipe_index] = kNoRecipeInput;
    catalog.roundabout_input1_qty[recipe_index] = 0;
    if (!inputs.is_array()) return;
    if (inputs.size() > 0u) {
        catalog.roundabout_input0_good[recipe_index] =
            ResolveGoodIndex(catalog, inputs[0].at("good").get<std::string>());
        catalog.roundabout_input0_qty[recipe_index] = inputs[0].at("qty").get<int>();
    }
    if (inputs.size() > 1u) {
        catalog.roundabout_input1_good[recipe_index] =
            ResolveGoodIndex(catalog, inputs[1].at("good").get<std::string>());
        catalog.roundabout_input1_qty[recipe_index] = inputs[1].at("qty").get<int>();
    }
    if (inputs.size() > 2u) {
        throw std::runtime_error("Roundabout recipes support at most two inputs");
    }
}

}  // namespace

std::filesystem::path ResolveCatalogPath() {
    const char* raw = std::getenv("AUSTRIAN_ABM_CATALOG_PATH");
    if (raw && *raw) return std::filesystem::path(raw);
    return std::filesystem::path("data/vic3_catalog.json");
}

SimulationCatalog LoadSimulationCatalog(const std::filesystem::path& path) {
    std::ifstream in(path);
    if (!in) {
        throw std::runtime_error("Failed to open catalog file: " + path.string());
    }

    nlohmann::json root;
    in >> root;

    SimulationCatalog catalog;

    const auto& goods = root.at("goods");
    if (!goods.is_array()) throw std::runtime_error("catalog.goods must be an array");
    if (goods.size() > kMaxGoods) {
        throw std::runtime_error("Too many goods in catalog (max " + std::to_string(kMaxGoods) + ")");
    }

    for (std::size_t i = 0; i < goods.size(); ++i) {
        const std::string id = goods[i].at("id").get<std::string>();
        if (catalog.good_index.contains(id)) {
            throw std::runtime_error("Duplicate good id: " + id);
        }
        catalog.good_index[id] = static_cast<int>(i);
    }
    catalog.good_count = static_cast<unsigned int>(goods.size());

    for (std::size_t i = 0; i < goods.size(); ++i) {
        const auto& row = goods[i];
        catalog.category[i] = ParseCategory(row.at("category").get<std::string>());
        catalog.utility[i] = row.at("utility").get<float>();
        catalog.default_price[i] = row.value("default_price", 1.0f);
        catalog.flags[i] = row.value("tradeable", true) ? kGoodFlagTradeable : 0u;
        catalog.complement[i] = kNoComplementGood;
        if (row.contains("complement")) {
            catalog.complement[i] = ResolveGoodIndex(catalog, row.at("complement").get<std::string>());
        }
    }

    const auto& recipes = root.at("recipes");
    if (!recipes.is_array()) throw std::runtime_error("catalog.recipes must be an array");
    if (recipes.size() > kMaxRecipes) {
        throw std::runtime_error("Too many recipes in catalog");
    }

    std::vector<nlohmann::json> recipe_rows;
    for (const auto& row : recipes) recipe_rows.push_back(row);
    std::sort(recipe_rows.begin(), recipe_rows.end(), [](const nlohmann::json& a, const nlohmann::json& b) {
        return a.value("priority", 0) > b.value("priority", 0);
    });

    for (std::size_t i = 0; i < recipe_rows.size(); ++i) {
        const auto& row = recipe_rows[i];
        const int recipe_index = static_cast<int>(i);
        catalog.recipe_output_good[recipe_index] =
            ResolveGoodIndex(catalog, row.at("output").get<std::string>());
        catalog.recipe_output_qty[recipe_index] = row.value("output_qty", 1);
        ParseRecipeInputs(row.at("inputs"), catalog, recipe_index);
        catalog.recipe_min_skill[recipe_index] = row.value("min_skill", 0.0f);
        catalog.recipe_activity[recipe_index] = ParseActivity(row.at("activity").get<std::string>());
        if (row.at("id").get<std::string>() == "food") {
            catalog.food_recipe_index = recipe_index;
        }
    }
    catalog.recipe_count = static_cast<unsigned int>(recipe_rows.size());
    if (catalog.food_recipe_index < 0) {
        throw std::runtime_error("Catalog must define a recipe with id 'food'");
    }

    const auto& roundabout = root.at("roundabout_recipes");
    if (!roundabout.is_array()) throw std::runtime_error("catalog.roundabout_recipes must be an array");
    if (roundabout.size() > kMaxRoundaboutRecipes) {
        throw std::runtime_error("Too many roundabout recipes in catalog");
    }

    std::vector<nlohmann::json> roundabout_rows;
    for (const auto& row : roundabout) roundabout_rows.push_back(row);
    std::sort(roundabout_rows.begin(), roundabout_rows.end(), [](const nlohmann::json& a, const nlohmann::json& b) {
        return a.value("stage", 0) < b.value("stage", 0);
    });

    for (std::size_t i = 0; i < roundabout_rows.size(); ++i) {
        const auto& row = roundabout_rows[i];
        const int recipe_index = static_cast<int>(i);
        catalog.roundabout_output_good[recipe_index] =
            ResolveGoodIndex(catalog, row.at("output").get<std::string>());
        catalog.roundabout_output_qty[recipe_index] = row.value("output_qty", 1);
        ParseRoundaboutInputs(row.at("inputs"), catalog, recipe_index);
    }
    catalog.roundabout_recipe_count = static_cast<unsigned int>(roundabout_rows.size());
    if (catalog.roundabout_recipe_count >= 1u) {
        catalog.credit_min_grain = catalog.roundabout_input0_qty[0];
        catalog.credit_min_fruit = catalog.roundabout_input1_qty[0];
    }

    std::printf("Loaded catalog %s: %u goods, %u recipes, %u roundabout stages\n",
        path.string().c_str(), catalog.good_count, catalog.recipe_count, catalog.roundabout_recipe_count);
    return catalog;
}

void UploadCatalogToEnvironment(flamegpu::EnvironmentDescription& env, const SimulationCatalog& catalog) {
    env.newProperty<unsigned int>("GOOD_COUNT", catalog.good_count);
    env.newProperty<unsigned int>("RECIPE_COUNT", catalog.recipe_count);
    env.newProperty<unsigned int>("ROUNDABOUT_RECIPE_COUNT", catalog.roundabout_recipe_count);
    env.newProperty<int>("FOOD_RECIPE_INDEX", catalog.food_recipe_index);
    env.newProperty<int>("CREDIT_MIN_GRAIN", catalog.credit_min_grain);
    env.newProperty<int>("CREDIT_MIN_FRUIT", catalog.credit_min_fruit);

    env.newProperty<int, kMaxGoods>("GOOD_CATEGORY", catalog.category);
    env.newProperty<float, kMaxGoods>("GOOD_UTILITY", catalog.utility);
    env.newProperty<unsigned int, kMaxGoods>("GOOD_FLAGS", catalog.flags);
    env.newProperty<int, kMaxGoods>("GOOD_COMPLEMENT", catalog.complement);
    env.newProperty<float, kMaxGoods>("LAST_PRICES", catalog.default_price);

    env.newProperty<int, kMaxRecipes>("RECIPE_OUTPUT_GOOD", catalog.recipe_output_good);
    env.newProperty<int, kMaxRecipes>("RECIPE_OUTPUT_QTY", catalog.recipe_output_qty);
    env.newProperty<int, kMaxRecipes>("RECIPE_INPUT0_GOOD", catalog.recipe_input0_good);
    env.newProperty<int, kMaxRecipes>("RECIPE_INPUT0_QTY", catalog.recipe_input0_qty);
    env.newProperty<int, kMaxRecipes>("RECIPE_INPUT1_GOOD", catalog.recipe_input1_good);
    env.newProperty<int, kMaxRecipes>("RECIPE_INPUT1_QTY", catalog.recipe_input1_qty);
    env.newProperty<float, kMaxRecipes>("RECIPE_MIN_SKILL", catalog.recipe_min_skill);
    env.newProperty<int, kMaxRecipes>("RECIPE_ACTIVITY", catalog.recipe_activity);

    env.newProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_OUTPUT_GOOD", catalog.roundabout_output_good);
    env.newProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_OUTPUT_QTY", catalog.roundabout_output_qty);
    env.newProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_INPUT0_GOOD", catalog.roundabout_input0_good);
    env.newProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_INPUT0_QTY", catalog.roundabout_input0_qty);
    env.newProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_INPUT1_GOOD", catalog.roundabout_input1_good);
    env.newProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_INPUT1_QTY", catalog.roundabout_input1_qty);
}

float CatalogUtility(const SimulationCatalog& catalog, const int good) {
    if (good < 0 || static_cast<unsigned int>(good) >= catalog.good_count) return 1.0f;
    return catalog.utility[good];
}

}  // namespace austrian_abm
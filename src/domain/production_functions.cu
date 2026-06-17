#include "flamegpu/flamegpu.h"

#include "data/catalog_env.cuh"
#include "data/constants.cuh"
#include "data/goods_catalog.cuh"
#include "domain/capital_functions.cuh"
#include "domain/inventory.cuh"
#include "domain/production_functions.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DEF(ChooseProductionActivity, flamegpu::MessageNone, flamegpu::MessageNone) {
    const int status = FLAMEGPU->getVariable<int>("status");
    if (status != kAgentStatusOccupied) {
        FLAMEGPU->setVariable<int>("activity_mode", kActivityHarvest);
        FLAMEGPU->setVariable<int>("step_production", 0);
        FLAMEGPU->setVariable<int>("step_investment", 0);
        return flamegpu::ALIVE;
    }

    const float production_skill = FLAMEGPU->getVariable<float>("production_skill");
    const float time_preference = FLAMEGPU->getVariable<float>("time_preference");
    const float money = FLAMEGPU->getVariable<float>("money");
    const int capital_stock = FLAMEGPU->getVariable<int>("capital_stock");
    const int grain = InventoryGet(FLAMEGPU, kGoodGrain);
    const int fruit = InventoryGet(FLAMEGPU, kGoodFruit);
    const float grain_price = FLAMEGPU->environment.getProperty<float, kMaxGoods>("LAST_PRICES", kGoodGrain);
    const float fruit_price = FLAMEGPU->environment.getProperty<float, kMaxGoods>("LAST_PRICES", kGoodFruit);
    const unsigned int good_stages = FLAMEGPU->environment.getProperty<unsigned int>("GOOD_STAGES");
    const float effective_rate = FLAMEGPU->environment.getProperty<float>("EFFECTIVE_RATE");
    const float natural_rate = FLAMEGPU->environment.getProperty<float>("NATURAL_RATE");

    const int food_recipe = FLAMEGPU->environment.getProperty<int>("FOOD_RECIPE_INDEX");
    const int food_grain_qty = CatalogRecipeInput0Qty(FLAMEGPU, food_recipe);
    const int food_fruit_qty = CatalogRecipeInput1Qty(FLAMEGPU, food_recipe);
    const int roundabout_min_grain = CatalogRoundaboutInput0Qty(FLAMEGPU, 0);
    const int roundabout_min_fruit = CatalogRoundaboutInput1Qty(FLAMEGPU, 0);

    FLAMEGPU->setVariable<int>("activity_mode", ChooseEconomicActivity(
        production_skill, time_preference, money, capital_stock,
        grain, fruit, grain_price, fruit_price,
        effective_rate, natural_rate, good_stages,
        roundabout_min_grain, roundabout_min_fruit, food_grain_qty, food_fruit_qty));
    FLAMEGPU->setVariable<int>("step_production", 0);
    FLAMEGPU->setVariable<int>("step_investment", 0);
    return flamegpu::ALIVE;
}

FLAMEGPU_AGENT_FUNCTION_DEF(ProduceFromRecipes, flamegpu::MessageNone, flamegpu::MessageNone) {
    const int status = FLAMEGPU->getVariable<int>("status");
    if (status != kAgentStatusOccupied) return flamegpu::ALIVE;

    const int activity_mode = FLAMEGPU->getVariable<int>("activity_mode");
    const float production_skill = FLAMEGPU->getVariable<float>("production_skill");
    const unsigned int recipe_count = CatalogRecipeCount(FLAMEGPU);

    for (unsigned int i = 0u; i < recipe_count; ++i) {
        const int recipe_activity = CatalogRecipeActivity(FLAMEGPU, static_cast<int>(i));
        if (recipe_activity != kRecipeAnyActivity && recipe_activity != activity_mode) continue;
        if (production_skill < CatalogRecipeMinSkill(FLAMEGPU, static_cast<int>(i))) continue;
        if (!CatalogInstantRecipeHasInputs(FLAMEGPU, static_cast<int>(i))) continue;
        CatalogInstantRecipeApply(FLAMEGPU, static_cast<int>(i));
        FLAMEGPU->setVariable<int>("step_production", 1);
        break;
    }
    return flamegpu::ALIVE;
}

}  // namespace austrian_abm
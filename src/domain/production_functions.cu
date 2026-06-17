#include "flamegpu/flamegpu.h"

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
    const float grain_price = FLAMEGPU->environment.getProperty<float, kGoodCount>("LAST_PRICES", kGoodGrain);
    const float fruit_price = FLAMEGPU->environment.getProperty<float, kGoodCount>("LAST_PRICES", kGoodFruit);
    const unsigned int good_stages = FLAMEGPU->environment.getProperty<unsigned int>("GOOD_STAGES");
    const float effective_rate = FLAMEGPU->environment.getProperty<float>("EFFECTIVE_RATE");
    const float natural_rate = FLAMEGPU->environment.getProperty<float>("NATURAL_RATE");

    FLAMEGPU->setVariable<int>("activity_mode", ChooseEconomicActivity(
        production_skill, time_preference, money, capital_stock,
        grain, fruit, grain_price, fruit_price,
        effective_rate, natural_rate, good_stages));
    FLAMEGPU->setVariable<int>("step_production", 0);
    FLAMEGPU->setVariable<int>("step_investment", 0);
    return flamegpu::ALIVE;
}

FLAMEGPU_AGENT_FUNCTION_DEF(ProduceFood, flamegpu::MessageNone, flamegpu::MessageNone) {
    const int status = FLAMEGPU->getVariable<int>("status");
    if (status != kAgentStatusOccupied) return flamegpu::ALIVE;
    if (FLAMEGPU->getVariable<int>("activity_mode") != kActivityProduce) return flamegpu::ALIVE;

    if (InventoryGet(FLAMEGPU, kGoodGrain) < kFoodRecipeSugar
        || InventoryGet(FLAMEGPU, kGoodFruit) < kFoodRecipeSpice) {
        return flamegpu::ALIVE;
    }

    InventoryAdd(FLAMEGPU, kGoodGrain, -kFoodRecipeSugar);
    InventoryAdd(FLAMEGPU, kGoodFruit, -kFoodRecipeSpice);
    InventoryAdd(FLAMEGPU, kGoodFood, 1);
    FLAMEGPU->setVariable<int>("step_production", 1);
    return flamegpu::ALIVE;
}

FLAMEGPU_AGENT_FUNCTION_DEF(ProduceIndustrialGoods, flamegpu::MessageNone, flamegpu::MessageNone) {
    const int status = FLAMEGPU->getVariable<int>("status");
    if (status != kAgentStatusOccupied) return flamegpu::ALIVE;
    if (FLAMEGPU->getVariable<float>("production_skill") < kMinProductionSkill) return flamegpu::ALIVE;

    if (InventoryGet(FLAMEGPU, kGoodSteel) >= kEnginesRecipeSteel
        && InventoryGet(FLAMEGPU, kGoodTools) >= kEnginesRecipeTools) {
        InventoryAdd(FLAMEGPU, kGoodSteel, -kEnginesRecipeSteel);
        InventoryAdd(FLAMEGPU, kGoodTools, -kEnginesRecipeTools);
        InventoryAdd(FLAMEGPU, kGoodEngines, 1);
        FLAMEGPU->setVariable<int>("step_production", 1);
        return flamegpu::ALIVE;
    }
    if (InventoryGet(FLAMEGPU, kGoodIron) >= kSteelRecipeIron
        && InventoryGet(FLAMEGPU, kGoodCoal) >= kSteelRecipeCoal) {
        InventoryAdd(FLAMEGPU, kGoodIron, -kSteelRecipeIron);
        InventoryAdd(FLAMEGPU, kGoodCoal, -kSteelRecipeCoal);
        InventoryAdd(FLAMEGPU, kGoodSteel, 1);
        FLAMEGPU->setVariable<int>("step_production", 1);
        return flamegpu::ALIVE;
    }
    if (InventoryGet(FLAMEGPU, kGoodIron) >= kToolsRecipeIron
        && InventoryGet(FLAMEGPU, kGoodCoal) >= kToolsRecipeCoal) {
        InventoryAdd(FLAMEGPU, kGoodIron, -kToolsRecipeIron);
        InventoryAdd(FLAMEGPU, kGoodCoal, -kToolsRecipeCoal);
        InventoryAdd(FLAMEGPU, kGoodTools, 1);
        FLAMEGPU->setVariable<int>("step_production", 1);
    }
    return flamegpu::ALIVE;
}

}  // namespace austrian_abm
#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "domain/production_functions.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DEF(ChooseProductionActivity, flamegpu::MessageNone, flamegpu::MessageNone) {
    const int status = FLAMEGPU->getVariable<int>("status");
    if (status != kAgentStatusOccupied) {
        FLAMEGPU->setVariable<int>("activity_mode", kActivityHarvest);
        FLAMEGPU->setVariable<int>("step_production", 0);
        return flamegpu::ALIVE;
    }

    const float production_skill = FLAMEGPU->getVariable<float>("production_skill");
    const int sugar_level = FLAMEGPU->getVariable<int>("sugar_level");
    const int spice_level = FLAMEGPU->getVariable<int>("spice_level");
    const float sugar_price = FLAMEGPU->environment.getProperty<float>("LAST_SUGAR_PRICE");
    const float spice_price = FLAMEGPU->environment.getProperty<float>("LAST_SPICE_PRICE");

    FLAMEGPU->setVariable<int>("activity_mode", ChooseActivityMode(
        production_skill, sugar_price, spice_price, sugar_level, spice_level));
    FLAMEGPU->setVariable<int>("step_production", 0);
    return flamegpu::ALIVE;
}

FLAMEGPU_AGENT_FUNCTION_DEF(ProduceFood, flamegpu::MessageNone, flamegpu::MessageNone) {
    const int status = FLAMEGPU->getVariable<int>("status");
    if (status != kAgentStatusOccupied) return flamegpu::ALIVE;
    if (FLAMEGPU->getVariable<int>("activity_mode") != kActivityProduce) return flamegpu::ALIVE;

    int sugar_level = FLAMEGPU->getVariable<int>("sugar_level");
    int spice_level = FLAMEGPU->getVariable<int>("spice_level");
    if (sugar_level < kFoodRecipeSugar || spice_level < kFoodRecipeSpice) return flamegpu::ALIVE;

    sugar_level -= kFoodRecipeSugar;
    spice_level -= kFoodRecipeSpice;
    const int food_level = FLAMEGPU->getVariable<int>("food_level") + 1;

    FLAMEGPU->setVariable<int>("sugar_level", sugar_level);
    FLAMEGPU->setVariable<int>("spice_level", spice_level);
    FLAMEGPU->setVariable<int>("food_level", food_level);
    FLAMEGPU->setVariable<int>("step_production", 1);
    return flamegpu::ALIVE;
}

}  // namespace austrian_abm
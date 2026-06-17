#pragma once

#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "util/math.cuh"

namespace austrian_abm {

FLAMEGPU_HOST_DEVICE_FUNCTION float ProductionNetBenefit(
    const float production_skill,
    const float sugar_price,
    const float spice_price,
    const int sugar_level,
    const int spice_level) {
    if (sugar_level < kFoodRecipeSugar || spice_level < kFoodRecipeSpice) return -1.0f;
    const float ingredient_value =
        sugar_price * static_cast<float>(kFoodRecipeSugar)
        + spice_price * static_cast<float>(kFoodRecipeSpice);
    const float food_value = kFoodValueMultiplier * static_cast<float>(kFoodMetabolismValue)
        * production_skill * (sugar_price + spice_price) * 0.5f;
    return food_value - ingredient_value;
}

FLAMEGPU_HOST_DEVICE_FUNCTION int ChooseActivityMode(
    const float production_skill,
    const float sugar_price,
    const float spice_price,
    const int sugar_level,
    const int spice_level) {
    const float benefit = ProductionNetBenefit(
        production_skill, sugar_price, spice_price, sugar_level, spice_level);
    if (benefit > 0.0f && production_skill >= kMinProductionSkill) {
        return kActivityProduce;
    }
    return kActivityHarvest;
}

}  // namespace austrian_abm
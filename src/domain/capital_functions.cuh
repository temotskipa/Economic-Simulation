#pragma once

#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "domain/present_value.cuh"
#include "domain/production_functions.cuh"

namespace austrian_abm {

FLAMEGPU_HOST_DEVICE_FUNCTION float RoundaboutFoodValue(
    const float production_skill,
    const float sugar_price,
    const float spice_price) {
    return kRoundaboutFoodMultiplier * kFoodValueMultiplier * static_cast<float>(kFoodMetabolismValue)
        * production_skill * (sugar_price + spice_price) * 0.5f;
}

FLAMEGPU_HOST_DEVICE_FUNCTION float DirectFoodValue(
    const float production_skill,
    const float sugar_price,
    const float spice_price) {
    return kFoodValueMultiplier * static_cast<float>(kFoodMetabolismValue)
        * production_skill * (sugar_price + spice_price) * 0.5f;
}

FLAMEGPU_HOST_DEVICE_FUNCTION float ExpectedCapitalReturn(
    const float production_skill,
    const float sugar_price,
    const float spice_price) {
    return kCapitalValuePerUnit
        + 0.25f * production_skill * (sugar_price + spice_price);
}

FLAMEGPU_HOST_DEVICE_FUNCTION int ChooseEconomicActivity(
    const float production_skill,
    const float time_preference,
    const float money,
    const int capital_stock,
    const int sugar_level,
    const int spice_level,
    const float sugar_price,
    const float spice_price,
    const unsigned int good_stages) {
    if (good_stages >= 2u
        && time_preference <= kCapitalOwnerMaxTimePreference
        && money >= kCapitalUnitCost) {
        const float pv_invest = PresentValue(
            ExpectedCapitalReturn(production_skill, sugar_price, spice_price),
            time_preference,
            2);
        if (pv_invest >= kCapitalUnitCost) {
            return kActivityInvest;
        }
    }

    if (good_stages >= 2u
        && sugar_level >= kIntermediateRecipeSugar
        && spice_level >= kIntermediateRecipeSpice) {
        const int total_periods =
            EffectiveProductionPeriod(kRoundaboutIntermediatePeriod, capital_stock)
            + EffectiveProductionPeriod(kRoundaboutFinalPeriod, capital_stock);
        const float pv_roundabout = PresentValue(
            RoundaboutFoodValue(production_skill, sugar_price, spice_price),
            time_preference,
            total_periods);
        const float pv_direct = PresentValue(
            DirectFoodValue(production_skill, sugar_price, spice_price),
            time_preference,
            kDirectProductionPeriod);
        if (pv_roundabout > pv_direct && pv_roundabout > 0.0f) {
            return kActivityRoundabout;
        }
    }

    return ChooseActivityMode(
        production_skill, sugar_price, spice_price, sugar_level, spice_level);
}

}  // namespace austrian_abm
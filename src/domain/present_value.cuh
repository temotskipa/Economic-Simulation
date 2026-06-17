#pragma once

#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"

namespace austrian_abm {

FLAMEGPU_HOST_DEVICE_FUNCTION float PresentValue(
    const float future_value,
    const float discount_rate,
    const int periods) {
    if (periods <= 0) return future_value;
    float discount_factor = 1.0f;
    for (int i = 0; i < periods; ++i) {
        discount_factor *= 1.0f + discount_rate;
    }
    return future_value / discount_factor;
}

FLAMEGPU_HOST_DEVICE_FUNCTION int EffectiveProductionPeriod(
    const int base_period,
    const int capital_stock) {
    const int reduction = static_cast<int>(
        static_cast<float>(capital_stock) * kCapitalEfficiencyPerUnit);
    const int period = base_period - reduction;
    return period < 1 ? 1 : period;
}

}  // namespace austrian_abm
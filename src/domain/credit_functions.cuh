#pragma once

#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "data/goods_catalog.cuh"
#include "util/math.cuh"

namespace austrian_abm {

FLAMEGPU_HOST_DEVICE_FUNCTION float CreditAdjustedDiscount(
    const float time_preference,
    const float effective_rate,
    const float natural_rate) {
    if (natural_rate <= 0.0f || effective_rate >= natural_rate) return time_preference;
    const float subsidy = (natural_rate - effective_rate) / natural_rate;
    return ClampFloat(time_preference * (1.0f - 0.6f * subsidy), kMinTimePreference, kMaxTimePreference);
}

FLAMEGPU_HOST_DEVICE_FUNCTION bool IsEntrepreneurEligibleForCredit(
    const float production_skill,
    const int grain_level,
    const int fruit_level,
    const float loan_balance,
    const int min_grain,
    const int min_fruit) {
    return production_skill >= kEntrepreneurMinSkill
        && grain_level >= min_grain
        && fruit_level >= min_fruit
        && loan_balance < kMaxLoanBalance;
}

FLAMEGPU_HOST_DEVICE_FUNCTION bool IsMalinvestment(
    const int activity_mode,
    const float loan_balance,
    const unsigned int rate_suppressed) {
    return rate_suppressed > 0u
        && activity_mode == kActivityRoundabout
        && loan_balance > 0.0f;
}

}  // namespace austrian_abm
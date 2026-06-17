#pragma once

#include "flamegpu/flamegpu.h"

#include "util/math.cuh"

namespace austrian_abm {

FLAMEGPU_HOST_DEVICE_FUNCTION float MarginalUtilityForGood(
    const float utility_weight,
    const int held,
    const int peer_held) {
    return utility_weight
        / (1.0f + static_cast<float>(held) + 0.25f * static_cast<float>(peer_held));
}

FLAMEGPU_HOST_DEVICE_FUNCTION float ReservationBidPrice(
    const float money, const float marginal_utility, const float mrs_peer) {
    if (money <= 0.0f || marginal_utility <= 0.0f) return 0.0f;
    const float budget = ClampFloat(money * 0.2f, 0.0f, money);
    return ClampFloat(marginal_utility * budget / (mrs_peer + 0.01f), 0.01f, money);
}

FLAMEGPU_HOST_DEVICE_FUNCTION float ReservationAskPrice(
    const int inventory, const float marginal_utility, const float market_hint) {
    if (inventory <= 0) return 0.0f;
    const float scarcity = 1.0f + 0.05f * static_cast<float>(inventory);
    const float anchor = market_hint > 0.0f ? market_hint : 1.0f;
    return ClampFloat(marginal_utility * scarcity + anchor * 0.1f, 0.01f, 1000.0f);
}

}  // namespace austrian_abm
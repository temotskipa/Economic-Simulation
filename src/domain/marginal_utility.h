#pragma once

namespace austrian_abm {
namespace detail {

inline float ClampUnit(float value, float lo, float hi) {
    return value < lo ? lo : (value > hi ? hi : value);
}

inline float SubjectiveReservationPrice(
    const float cash, const float time_preference, const float goods_held, const float base_utility) {
    const float satiation = 1.0f / (1.0f + goods_held);
    const float urgency = ClampUnit(1.0f - time_preference, 0.05f, 1.0f);
    const float budget_share = ClampUnit(cash * 0.15f * urgency, 0.01f, cash);
    return ClampUnit(base_utility * satiation + budget_share, 0.01f, cash);
}

inline float EntrepreneurAskPrice(
    const float unit_cost, const float inventory, const float alertness, const float market_price) {
    const float scarcity_premium = ClampUnit(1.0f + inventory * 0.02f, 1.0f, 2.5f);
    const float discovery_markup = 1.0f + alertness * 0.25f;
    const float anchor = market_price > 0.0f ? market_price : unit_cost;
    return ClampUnit(unit_cost * scarcity_premium * discovery_markup + anchor * 0.05f, 0.01f, 1000.0f);
}

}  // namespace detail
}  // namespace austrian_abm
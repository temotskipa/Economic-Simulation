#include "flamegpu/flamegpu.h"

#include "domain/marginal_utility.cuh"
#include "model/model_symbols.cuh"
#include "util/math.cuh"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DEF(ConsumerPlanPurchase, flamegpu::MessageNone, flamegpu::MessageNone) {
    const float market_price = FLAMEGPU->environment.getProperty<float>("CLEARING_PRICE");
    const float cash = FLAMEGPU->getVariable<float>("cash");
    const float time_preference = FLAMEGPU->getVariable<float>("time_preference");
    const float goods_held = FLAMEGPU->getVariable<float>("goods_held");
    const float base_utility = FLAMEGPU->getVariable<float>("base_utility");

    const float reservation = SubjectiveReservationPrice(cash, time_preference, goods_held, base_utility);
    float desired_qty = 0.0f;
    if (reservation >= market_price && market_price > 0.0f) {
        desired_qty = ClampFloat((cash * 0.2f) / market_price, 0.0f, 5.0f);
    }

    FLAMEGPU->setVariable<float>("reservation_price", reservation);
    FLAMEGPU->setVariable<float>("desired_qty", desired_qty);
    return flamegpu::ALIVE;
}

FLAMEGPU_AGENT_FUNCTION_DEF(ConsumerExecuteTrade, flamegpu::MessageNone, flamegpu::MessageNone) {
    const float market_price = FLAMEGPU->environment.getProperty<float>("CLEARING_PRICE");
    float cash = FLAMEGPU->getVariable<float>("cash");
    float goods_held = FLAMEGPU->getVariable<float>("goods_held");
    const float desired_qty = FLAMEGPU->getVariable<float>("desired_qty");
    const float reservation = FLAMEGPU->getVariable<float>("reservation_price");

    float traded_qty = 0.0f;
    if (desired_qty > 0.0f && reservation >= market_price) {
        traded_qty = desired_qty;
        const float spend = traded_qty * market_price;
        if (spend <= cash) {
            cash -= spend;
            goods_held += traded_qty;
        } else {
            traded_qty = 0.0f;
        }
    }

    FLAMEGPU->setVariable<float>("cash", cash);
    FLAMEGPU->setVariable<float>("goods_held", goods_held);
    FLAMEGPU->setVariable<float>("last_trade_qty", traded_qty);
    return flamegpu::ALIVE;
}

}  // namespace austrian_abm
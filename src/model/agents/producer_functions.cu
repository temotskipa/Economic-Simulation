#include "flamegpu/flamegpu.h"

#include "domain/marginal_utility.cuh"
#include "model/model_symbols.cuh"
#include "util/math.cuh"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DEF(ProducerProduce, flamegpu::MessageNone, flamegpu::MessageNone) {
    const float productivity = FLAMEGPU->getVariable<float>("productivity");
    const float capital = FLAMEGPU->getVariable<float>("capital");
    float inventory = FLAMEGPU->getVariable<float>("inventory");

    const float output = ClampFloat(productivity * capital * 0.01f, 0.0f, 20.0f);
    inventory += output;
    FLAMEGPU->setVariable<float>("inventory", inventory);
    FLAMEGPU->setVariable<float>("last_output", output);
    return flamegpu::ALIVE;
}

FLAMEGPU_AGENT_FUNCTION_DEF(ProducerSetPrice, flamegpu::MessageNone, flamegpu::MessageNone) {
    const float market_price = FLAMEGPU->environment.getProperty<float>("CLEARING_PRICE");
    const float unit_cost = FLAMEGPU->getVariable<float>("unit_cost");
    const float inventory = FLAMEGPU->getVariable<float>("inventory");
    const float alertness = FLAMEGPU->getVariable<float>("alertness");

    const float ask_price = EntrepreneurAskPrice(unit_cost, inventory, alertness, market_price);
    FLAMEGPU->setVariable<float>("ask_price", ask_price);
    return flamegpu::ALIVE;
}

}  // namespace austrian_abm
#include <cstdio>

#include "flamegpu/flamegpu.h"

#include "model/model_symbols.cuh"
#include "util/math.cuh"

namespace austrian_abm {

FLAMEGPU_STEP_FUNCTION(AdvanceMarket) {
    flamegpu::DeviceAgentVector consumer_data = FLAMEGPU->agent("consumer").getPopulationData();
    flamegpu::DeviceAgentVector producer_data = FLAMEGPU->agent("producer").getPopulationData();

    double demand_qty = 0.0;
    double demand_value = 0.0;
    for (const auto& c : consumer_data) {
        demand_qty += c.getVariable<float>("desired_qty");
        demand_value += c.getVariable<float>("reservation_price");
    }

    double supply_qty = 0.0;
    double ask_sum = 0.0;
    for (const auto& p : producer_data) {
        supply_qty += p.getVariable<float>("inventory");
        ask_sum += p.getVariable<float>("ask_price");
    }

    const float old_price = FLAMEGPU->environment.getProperty<float>("CLEARING_PRICE");
    const unsigned int producer_pop = static_cast<unsigned int>(producer_data.size());
    const unsigned int consumer_pop = static_cast<unsigned int>(consumer_data.size());
    const float avg_ask = producer_pop > 0 ? static_cast<float>(ask_sum / producer_pop) : old_price;
    const float avg_bid = consumer_pop > 0 ? static_cast<float>(demand_value / consumer_pop) : old_price;

    float imbalance = 0.0f;
    if (supply_qty > 0.0) {
        imbalance = static_cast<float>((demand_qty - supply_qty) / supply_qty);
    }

    float new_price = old_price * (1.0f + imbalance * 0.15f);
    new_price = 0.5f * new_price + 0.25f * avg_ask + 0.25f * avg_bid;
    new_price = ClampFloat(new_price, 0.01f, 100.0f);

    FLAMEGPU->environment.setProperty<float>("CLEARING_PRICE", new_price);

    const unsigned int step = FLAMEGPU->environment.getProperty<unsigned int>("MARKET_STEP");
    FLAMEGPU->environment.setProperty<unsigned int>("MARKET_STEP", step + 1u);

    if (step == 0u || (step + 1u) % 3u == 0u) {
        std::printf("step=%u price=%.4f demand=%.1f supply=%.1f consumers=%u producers=%u\n",
            step, new_price, demand_qty, supply_qty, consumer_pop, producer_pop);
    }
}

}  // namespace austrian_abm
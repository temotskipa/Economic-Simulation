#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_INIT_FUNCTION(SeedConsumers) {
    const unsigned int count = FLAMEGPU->environment.getProperty<unsigned int>("CONSUMER_COUNT");
    flamegpu::HostAgentAPI consumers = FLAMEGPU->agent("consumer");

    for (unsigned int i = 0; i < count; ++i) {
        flamegpu::HostNewAgentAPI c = consumers.newAgent();
        const float cash = 50.0f + FLAMEGPU->random.uniform<float>(0.0f, 150.0f);
        c.setVariable<float>("cash", cash);
        c.setVariable<float>("goods_held", FLAMEGPU->random.uniform<float>(0.0f, 3.0f));
        c.setVariable<float>("time_preference", FLAMEGPU->random.uniform<float>(0.05f, 0.95f));
        c.setVariable<float>("base_utility", FLAMEGPU->random.uniform<float>(0.5f, 2.5f));
        c.setVariable<float>("reservation_price", 0.0f);
        c.setVariable<float>("desired_qty", 0.0f);
        c.setVariable<float>("last_trade_qty", 0.0f);
    }
}

}  // namespace austrian_abm
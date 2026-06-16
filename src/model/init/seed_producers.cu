#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_INIT_FUNCTION(SeedProducers) {
    const unsigned int count = FLAMEGPU->environment.getProperty<unsigned int>("PRODUCER_COUNT");
    flamegpu::HostAgentAPI producers = FLAMEGPU->agent("producer");

    for (unsigned int i = 0; i < count; ++i) {
        flamegpu::HostNewAgentAPI p = producers.newAgent();
        const float capital = 10.0f + FLAMEGPU->random.uniform<float>(0.0f, 90.0f);
        p.setVariable<float>("capital", capital);
        p.setVariable<float>("productivity", FLAMEGPU->random.uniform<float>(0.4f, 1.6f));
        p.setVariable<float>("unit_cost", FLAMEGPU->random.uniform<float>(0.4f, 1.2f));
        p.setVariable<float>("alertness", FLAMEGPU->random.uniform<float>(0.0f, 1.0f));
        p.setVariable<float>("inventory", FLAMEGPU->random.uniform<float>(0.0f, 5.0f));
        p.setVariable<float>("ask_price", 1.0f);
        p.setVariable<float>("last_output", 0.0f);
    }
}

}  // namespace austrian_abm
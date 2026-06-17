#include <array>
#include <utility>

#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_INIT_FUNCTION(SeedBanks) {
    const unsigned int grid_width = FLAMEGPU->environment.getProperty<unsigned int>("GRID_WIDTH");
    const unsigned int grid_height = FLAMEGPU->environment.getProperty<unsigned int>("GRID_HEIGHT");
    flamegpu::HostAgentAPI banks = FLAMEGPU->agent("bank");

    const std::array<std::pair<unsigned int, unsigned int>, kDefaultBankCount> positions = {{
        {0u, 0u},
        {grid_width - 1u, 0u},
        {0u, grid_height - 1u},
        {grid_width - 1u, grid_height - 1u},
    }};

    for (unsigned int i = 0; i < kDefaultBankCount; ++i) {
        flamegpu::HostNewAgentAPI bank = banks.newAgent();
        bank.setVariable<unsigned int, 2>("pos", {positions[i].first, positions[i].second});
        bank.setVariable<int>("bank_id", static_cast<int>(i));
        bank.setVariable<float>("reserves", kBankInitialReserves);
        bank.setVariable<float>("deposits", 0.0f);
        bank.setVariable<float>("loans_outstanding", 0.0f);
    }
}

}  // namespace austrian_abm
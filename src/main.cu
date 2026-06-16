#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "io/config.h"
#include "model/build_model.h"

namespace austrian_abm {

void RunMain(int argc, const char** argv) {
    flamegpu::ModelDescription model(kModelName);
    BuildModel(model);
    flamegpu::CUDASimulation simulation(model);
    simulation.SimulationConfig().steps =
        ParseUnsignedEnv("AUSTRIAN_ABM_MARKET_STEPS", kDefaultMarketSteps);
    simulation.SimulationConfig().random_seed = ParseRandomSeedEnv();
    simulation.applyConfig();
    simulation.simulate();
}

}  // namespace austrian_abm

int main(int argc, const char** argv) {
    austrian_abm::RunMain(argc, argv);
    return 0;
}
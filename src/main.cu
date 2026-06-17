#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "io/config.h"
#include "io/report_html.h"
#include "model/build_model.h"

namespace austrian_abm {

void RunMain(int argc, const char** argv) {
    const SimulationConfig config = ParseSimulationConfig(argc, argv);
    flamegpu::ModelDescription model(kModelName);
    BuildModel(model, config);

    flamegpu::CUDASimulation simulation(model);
    simulation.SimulationConfig().steps = config.steps;
    simulation.SimulationConfig().random_seed = config.seed;
    simulation.applyConfig();
    simulation.simulate();

    flamegpu::AgentVector population(model.Agent("cell"));
    simulation.getPopulationData(population);
    WriteSimulationReport(population, config, ResolveReportDirectory());
}

}  // namespace austrian_abm

int main(int argc, const char** argv) {
    austrian_abm::RunMain(argc, argv);
    return 0;
}
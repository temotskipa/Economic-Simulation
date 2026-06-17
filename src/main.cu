#include "flamegpu/flamegpu.h"

#include <cstdio>
#include <exception>

#include "data/constants.cuh"
#include "io/catalog.h"
#include "io/config.h"
#include "io/report_html.h"
#include "model/build_model.h"

namespace austrian_abm {

void RunMain(int argc, const char** argv) {
    const SimulationConfig config = ParseSimulationConfig(argc, argv);
    const auto catalog_path = ResolveCatalogPath();
    const SimulationCatalog catalog = LoadSimulationCatalog(catalog_path);

    flamegpu::ModelDescription model(kModelName);
    BuildModel(model, config, catalog);

    flamegpu::CUDASimulation simulation(model);
    simulation.SimulationConfig().steps = config.steps;
    simulation.SimulationConfig().random_seed = config.seed;
    simulation.applyConfig();
    simulation.simulate();

    flamegpu::AgentVector population(model.Agent("cell"));
    simulation.getPopulationData(population);
    WriteSimulationReport(population, config, catalog, ResolveReportDirectory());
}

}  // namespace austrian_abm

int main(int argc, const char** argv) {
    try {
        austrian_abm::RunMain(argc, argv);
    } catch (const std::exception& ex) {
        std::printf("Fatal error: %s\n", ex.what());
        return 1;
    }
    return 0;
}
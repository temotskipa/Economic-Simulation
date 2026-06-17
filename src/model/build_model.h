#pragma once

#include "flamegpu/flamegpu.h"

#include "io/catalog.h"
#include "io/config.h"

namespace austrian_abm {

void BuildModel(
    flamegpu::ModelDescription& model,
    const SimulationConfig& config,
    const SimulationCatalog& catalog);

}  // namespace austrian_abm
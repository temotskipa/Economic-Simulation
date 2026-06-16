#pragma once

#include "flamegpu/flamegpu.h"

#include "io/config.h"

namespace austrian_abm {

void BuildModel(flamegpu::ModelDescription& model, const SimulationConfig& config);

}  // namespace austrian_abm
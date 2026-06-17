#pragma once

#include <filesystem>
#include <vector>

#include "flamegpu/flamegpu.h"

#include "host/step_log.h"
#include "io/catalog.h"
#include "io/config.h"

namespace austrian_abm {

std::vector<MarketStepMetrics> LoadMarketHistory(const std::filesystem::path& jsonl_path);

void WriteSimulationReport(
    const flamegpu::AgentVector& population,
    const SimulationConfig& config,
    const SimulationCatalog& catalog,
    const std::filesystem::path& report_dir);

}  // namespace austrian_abm
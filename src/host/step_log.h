#pragma once

#include "flamegpu/flamegpu.h"

namespace austrian_abm {

float ComputeWealthGini(flamegpu::DeviceAgentVector& population);

void AppendMarketHistory(
    unsigned int step,
    float avg_price,
    unsigned int trades_count,
    float trade_volume,
    float wealth_gini,
    unsigned int population,
    long long total_sugar,
    long long total_spice);

}  // namespace austrian_abm
#pragma once

#include "flamegpu/flamegpu.h"

namespace austrian_abm {

float ComputeWealthGini(flamegpu::DeviceAgentVector& population);

struct MarketStepMetrics {
    unsigned int step = 0u;
    float avg_price = 0.0f;
    unsigned int trades_count = 0u;
    float trade_volume = 0.0f;
    float wealth_gini = 0.0f;
    unsigned int population = 0u;
    long long total_sugar = 0;
    long long total_spice = 0;
    long long total_food = 0;
    unsigned int production_count = 0u;
    unsigned int producer_count = 0u;
    long long total_capital = 0;
    long long total_intermediate = 0;
    unsigned int investment_count = 0u;
    unsigned int roundabout_count = 0u;
    unsigned int capital_owner_count = 0u;
};

void AppendMarketHistory(const MarketStepMetrics& metrics);

}  // namespace austrian_abm
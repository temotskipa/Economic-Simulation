#include "host/step_log.h"

#include <algorithm>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <vector>

#include "data/constants.cuh"
#include "data/goods_catalog.cuh"
#include "io/config.h"

namespace austrian_abm {

float ComputeWealthGini(
    flamegpu::DeviceAgentVector& population,
    const flamegpu::HostEnvironment& environment) {
    const unsigned int good_count = environment.getProperty<unsigned int>("GOOD_COUNT");
    std::vector<float> wealth;
    wealth.reserve(population.size());
    for (const auto& cell : population) {
        if (cell.getVariable<int>("status") != kAgentStatusOccupied) continue;
        const float money = cell.getVariable<float>("money");
        float goods_value = 0.0f;
        for (unsigned int good = 0u; good < good_count; ++good) {
            goods_value += static_cast<float>(cell.getVariable<int, kMaxGoods>("inventory", good))
                * environment.getProperty<float, kMaxGoods>("GOOD_UTILITY", good);
        }
        const int capital = cell.getVariable<int>("capital_stock");
        wealth.push_back(money + goods_value
            + static_cast<float>(capital) * kCapitalValuePerUnit);
    }
    if (wealth.size() < 2u) return 0.0f;

    std::sort(wealth.begin(), wealth.end());
    double sum = 0.0;
    double weighted = 0.0;
    for (size_t i = 0; i < wealth.size(); ++i) {
        sum += wealth[i];
        weighted += static_cast<double>(i + 1) * wealth[i];
    }
    if (sum <= 0.0) return 0.0f;
    const double n = static_cast<double>(wealth.size());
    return static_cast<float>((2.0 * weighted) / (n * sum) - (n + 1.0) / n);
}

void AppendMarketHistory(const MarketStepMetrics& metrics) {
    const auto report_dir = ResolveReportDirectory();
    std::filesystem::create_directories(report_dir);
    const auto path = report_dir / "market_history.jsonl";
    std::ofstream out(path, std::ios::app);
    if (!out) {
        std::printf("Failed to open %s for append\n", path.string().c_str());
        return;
    }
    out << "{\"step\":" << metrics.step
        << ",\"avg_price\":" << metrics.avg_price
        << ",\"trades_count\":" << metrics.trades_count
        << ",\"trade_volume\":" << metrics.trade_volume
        << ",\"wealth_gini\":" << metrics.wealth_gini
        << ",\"population\":" << metrics.population
        << ",\"total_sugar\":" << metrics.total_sugar
        << ",\"total_spice\":" << metrics.total_spice
        << ",\"total_food\":" << metrics.total_food
        << ",\"total_res\":" << metrics.total_res
        << ",\"total_ind\":" << metrics.total_ind
        << ",\"total_tech\":" << metrics.total_tech
        << ",\"production_count\":" << metrics.production_count
        << ",\"producer_count\":" << metrics.producer_count
        << ",\"total_capital\":" << metrics.total_capital
        << ",\"total_intermediate\":" << metrics.total_intermediate
        << ",\"investment_count\":" << metrics.investment_count
        << ",\"roundabout_count\":" << metrics.roundabout_count
        << ",\"capital_owner_count\":" << metrics.capital_owner_count
        << ",\"credit_created\":" << metrics.credit_created
        << ",\"total_loans\":" << metrics.total_loans
        << ",\"effective_rate\":" << metrics.effective_rate
        << ",\"rate_suppressed\":" << metrics.rate_suppressed
        << ",\"malinvestment_count\":" << metrics.malinvestment_count
        << "}\n";
}

}  // namespace austrian_abm
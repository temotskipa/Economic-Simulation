#include "host/step_log.h"

#include <algorithm>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <vector>

#include "data/constants.cuh"
#include "io/config.h"

namespace austrian_abm {

float ComputeWealthGini(flamegpu::DeviceAgentVector& population) {
    std::vector<float> wealth;
    wealth.reserve(population.size());
    for (const auto& cell : population) {
        if (cell.getVariable<int>("status") != kAgentStatusOccupied) continue;
        const float money = cell.getVariable<float>("money");
        const int sugar = cell.getVariable<int>("sugar_level");
        const int spice = cell.getVariable<int>("spice_level");
        wealth.push_back(money + static_cast<float>(sugar) + static_cast<float>(spice));
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

void AppendMarketHistory(
    const unsigned int step,
    const float avg_price,
    const unsigned int trades_count,
    const float trade_volume,
    const float wealth_gini,
    const unsigned int population,
    const long long total_sugar,
    const long long total_spice) {
    const auto report_dir = ResolveReportDirectory();
    std::filesystem::create_directories(report_dir);
    const auto path = report_dir / "market_history.jsonl";
    std::ofstream out(path, std::ios::app);
    if (!out) {
        std::printf("Failed to open %s for append\n", path.string().c_str());
        return;
    }
    out << "{\"step\":" << step
        << ",\"avg_price\":" << avg_price
        << ",\"trades_count\":" << trades_count
        << ",\"trade_volume\":" << trade_volume
        << ",\"wealth_gini\":" << wealth_gini
        << ",\"population\":" << population
        << ",\"total_sugar\":" << total_sugar
        << ",\"total_spice\":" << total_spice
        << "}\n";
}

}  // namespace austrian_abm
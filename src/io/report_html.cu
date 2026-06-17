#include "io/report_html.h"

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <string>

#include "data/constants.cuh"

namespace austrian_abm {

namespace {

float ParseJsonFloat(const std::string& line, const char* key) {
    const std::string needle = std::string("\"") + key + "\":";
    const size_t pos = line.find(needle);
    if (pos == std::string::npos) return 0.0f;
    return std::strtof(line.c_str() + pos + needle.size(), nullptr);
}

unsigned int ParseJsonUint(const std::string& line, const char* key) {
    const std::string needle = std::string("\"") + key + "\":";
    const size_t pos = line.find(needle);
    if (pos == std::string::npos) return 0u;
    return static_cast<unsigned int>(std::strtoull(line.c_str() + pos + needle.size(), nullptr, 10));
}

long long ParseJsonLong(const std::string& line, const char* key) {
    const std::string needle = std::string("\"") + key + "\":";
    const size_t pos = line.find(needle);
    if (pos == std::string::npos) return 0;
    return std::strtoll(line.c_str() + pos + needle.size(), nullptr, 10);
}

MarketStepMetrics ParseMarketLine(const std::string& line) {
    MarketStepMetrics metrics;
    metrics.step = ParseJsonUint(line, "step");
    metrics.avg_price = ParseJsonFloat(line, "avg_price");
    metrics.trades_count = ParseJsonUint(line, "trades_count");
    metrics.trade_volume = ParseJsonFloat(line, "trade_volume");
    metrics.wealth_gini = ParseJsonFloat(line, "wealth_gini");
    metrics.population = ParseJsonUint(line, "population");
    metrics.total_sugar = ParseJsonLong(line, "total_sugar");
    metrics.total_spice = ParseJsonLong(line, "total_spice");
    metrics.total_food = ParseJsonLong(line, "total_food");
    metrics.production_count = ParseJsonUint(line, "production_count");
    metrics.producer_count = ParseJsonUint(line, "producer_count");
    return metrics;
}

std::string ColorFromUnit(const float unit) {
    const int r = static_cast<int>(255.0f * (1.0f - unit));
    const int g = static_cast<int>(80.0f + 120.0f * unit);
    const int b = static_cast<int>(40.0f + 180.0f * (1.0f - unit));
    std::ostringstream css;
    css << "rgb(" << r << "," << g << "," << b << ")";
    return css.str();
}

std::string BuildGridMapSvg(
    const flamegpu::AgentVector& population,
    const unsigned int grid_width,
    const unsigned int grid_height,
    const char* title,
    const char* mode) {
    const unsigned int cell_px = 2u;
    const unsigned int svg_w = grid_width * cell_px;
    const unsigned int svg_h = grid_height * cell_px;
    float max_value = 1.0f;

    std::vector<float> values(grid_width * grid_height, 0.0f);
    for (const auto& cell : population) {
        const unsigned int x = cell.getVariable<unsigned int, 2>("pos", 0);
        const unsigned int y = cell.getVariable<unsigned int, 2>("pos", 1);
        if (x >= grid_width || y >= grid_height) continue;
        const size_t idx = static_cast<size_t>(y) * grid_width + x;
        if (std::strcmp(mode, "wealth") == 0) {
            if (cell.getVariable<int>("status") == kAgentStatusOccupied) {
                values[idx] = cell.getVariable<float>("money")
                    + static_cast<float>(cell.getVariable<int>("sugar_level"))
                    + static_cast<float>(cell.getVariable<int>("spice_level"))
                    + static_cast<float>(cell.getVariable<int>("food_level")) * kFoodValueMultiplier;
            }
        } else if (std::strcmp(mode, "sugar") == 0) {
            values[idx] = static_cast<float>(cell.getVariable<int>("env_sugar_level"));
            if (values[idx] < 0.0f) {
                values[idx] = static_cast<float>(cell.getVariable<int>("sugar_level"));
            }
        } else {
            values[idx] = static_cast<float>(cell.getVariable<int>("env_spice_level"));
            if (values[idx] < 0.0f) {
                values[idx] = static_cast<float>(cell.getVariable<int>("spice_level"));
            }
        }
        max_value = std::max(max_value, values[idx]);
    }

    std::ostringstream svg;
    svg << "<svg viewBox=\"0 0 " << svg_w << " " << svg_h
        << "\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"" << title << "\">\n"
        << "<title>" << title << "</title>\n";
    for (unsigned int y = 0; y < grid_height; ++y) {
        for (unsigned int x = 0; x < grid_width; ++x) {
            const float unit = values[static_cast<size_t>(y) * grid_width + x] / max_value;
            svg << "<rect x=\"" << (x * cell_px) << "\" y=\"" << (y * cell_px)
                << "\" width=\"" << cell_px << "\" height=\"" << cell_px
                << "\" fill=\"" << ColorFromUnit(unit) << "\"/>\n";
        }
    }
    svg << "</svg>\n";
    return svg.str();
}

std::string BuildWealthHistogramSvg(const flamegpu::AgentVector& population) {
    std::vector<float> wealth;
    for (const auto& cell : population) {
        if (cell.getVariable<int>("status") != kAgentStatusOccupied) continue;
        wealth.push_back(cell.getVariable<float>("money")
            + static_cast<float>(cell.getVariable<int>("sugar_level"))
            + static_cast<float>(cell.getVariable<int>("spice_level"))
            + static_cast<float>(cell.getVariable<int>("food_level")) * kFoodValueMultiplier);
    }
    if (wealth.empty()) return "<p>No occupied agents for wealth histogram.</p>";

    constexpr unsigned int bins = 16u;
    const float min_w = *std::min_element(wealth.begin(), wealth.end());
    const float max_w = *std::max_element(wealth.begin(), wealth.end());
    const float span = std::max(1.0f, max_w - min_w);
    std::vector<unsigned int> counts(bins, 0u);
    for (const float w : wealth) {
        const unsigned int bin = static_cast<unsigned int>(
            std::min(static_cast<float>(bins - 1u), ((w - min_w) / span) * static_cast<float>(bins)));
        ++counts[bin];
    }
    const unsigned int peak = *std::max_element(counts.begin(), counts.end());

    std::ostringstream svg;
    svg << "<svg viewBox=\"0 0 320 180\" xmlns=\"http://www.w3.org/2000/svg\">\n"
        << "<title>Wealth distribution</title>\n";
    for (unsigned int i = 0; i < bins; ++i) {
        const float height = peak > 0u ? 140.0f * static_cast<float>(counts[i]) / static_cast<float>(peak) : 0.0f;
        const float x = 20.0f + static_cast<float>(i) * 18.0f;
        svg << "<rect x=\"" << x << "\" y=\"" << (160.0f - height)
            << "\" width=\"14\" height=\"" << height << "\" fill=\"#38bdf8\"/>\n";
    }
    svg << "</svg>\n";
    return svg.str();
}

std::string BuildTradeChartSvg(const std::vector<MarketStepMetrics>& history) {
    if (history.empty()) return "<p>No trade history available.</p>";

    unsigned int peak_trades = 1u;
    unsigned int peak_production = 1u;
    for (const auto& row : history) {
        peak_trades = std::max(peak_trades, row.trades_count);
        peak_production = std::max(peak_production, row.production_count);
    }

    std::ostringstream svg;
    svg << "<svg viewBox=\"0 0 360 200\" xmlns=\"http://www.w3.org/2000/svg\">\n"
        << "<title>Trades and production by step</title>\n";
    const float step_w = 300.0f / static_cast<float>(history.size());
    for (size_t i = 0; i < history.size(); ++i) {
        const float x = 30.0f + static_cast<float>(i) * step_w;
        const float trade_h = 80.0f * static_cast<float>(history[i].trades_count) / static_cast<float>(peak_trades);
        const float prod_h = 80.0f * static_cast<float>(history[i].production_count) / static_cast<float>(peak_production);
        svg << "<rect x=\"" << x << "\" y=\"" << (170.0f - trade_h)
            << "\" width=\"" << (step_w * 0.45f) << "\" height=\"" << trade_h << "\" fill=\"#38bdf8\"/>\n";
        svg << "<rect x=\"" << (x + step_w * 0.5f) << "\" y=\"" << (170.0f - prod_h)
            << "\" width=\"" << (step_w * 0.45f) << "\" height=\"" << prod_h << "\" fill=\"#f59e0b\"/>\n";
    }
    svg << "<text x=\"30\" y=\"190\" fill=\"#94a3b8\" font-size=\"10\">blue=trades orange=production</text>\n"
        << "</svg>\n";
    return svg.str();
}

}  // namespace

std::vector<MarketStepMetrics> LoadMarketHistory(const std::filesystem::path& jsonl_path) {
    std::vector<MarketStepMetrics> history;
    std::ifstream in(jsonl_path);
    std::string line;
    while (std::getline(in, line)) {
        if (line.empty()) continue;
        history.push_back(ParseMarketLine(line));
    }
    return history;
}

void WriteSimulationReport(
    const flamegpu::AgentVector& population,
    const SimulationConfig& config,
    const std::filesystem::path& report_dir) {
    std::filesystem::create_directories(report_dir);
    const auto history = LoadMarketHistory(report_dir / "market_history.jsonl");
    const MarketStepMetrics& last = history.empty() ? MarketStepMetrics{} : history.back();

    const std::string wealth_hist = BuildWealthHistogramSvg(population);
    const std::string trade_chart = BuildTradeChartSvg(history);
    const std::string sugar_map = BuildGridMapSvg(
        population, config.grid_width, config.grid_height, "Sugar map", "sugar");
    const std::string spice_map = BuildGridMapSvg(
        population, config.grid_width, config.grid_height, "Spice map", "spice");
    const std::string wealth_map = BuildGridMapSvg(
        population, config.grid_width, config.grid_height, "Wealth map", "wealth");

    std::ostringstream html;
    html << "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n"
         << "<title>Austrian ABM Sugarscape Report</title>\n"
         << "<style>body{font-family:Inter,Segoe UI,sans-serif;background:#0f172a;color:#e2e8f0;"
         << "max-width:1100px;margin:0 auto;padding:2rem}"
         << "h1{color:#38bdf8;text-align:center}.card{background:#1e293b;border-radius:10px;"
         << "padding:1.25rem;margin:1rem 0}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:1rem}"
         << ".stat{color:#94a3b8;font-size:.85rem}.val{color:#f8fafc;font-size:1.2rem;font-weight:700}"
         << ".maps{display:grid;grid-template-columns:repeat(2,1fr);gap:1rem}svg{width:100%;height:auto}"
         << "</style></head><body>\n"
         << "<h1>Austrian ABM Sugarscape Report</h1>\n"
         << "<div class=\"grid\">\n"
         << "<div class=\"card\"><div class=\"stat\">Seed</div><div class=\"val\">" << config.seed << "</div></div>\n"
         << "<div class=\"card\"><div class=\"stat\">Steps</div><div class=\"val\">" << config.steps << "</div></div>\n"
         << "<div class=\"card\"><div class=\"stat\">Final population</div><div class=\"val\">" << last.population << "</div></div>\n"
         << "<div class=\"card\"><div class=\"stat\">Final trades</div><div class=\"val\">" << last.trades_count << "</div></div>\n"
         << "<div class=\"card\"><div class=\"stat\">Food produced (last step)</div><div class=\"val\">" << last.production_count << "</div></div>\n"
         << "<div class=\"card\"><div class=\"stat\">Active producers</div><div class=\"val\">" << last.producer_count << "</div></div>\n"
         << "</div>\n"
         << "<div class=\"card\"><h2>Wealth Distribution</h2>" << wealth_hist << "</div>\n"
         << "<div class=\"card\"><h2>Trade Network Activity</h2>" << trade_chart << "</div>\n"
         << "<div class=\"maps\">\n"
         << "<div class=\"card\"><h2>Resource Map — Sugar</h2>" << sugar_map << "</div>\n"
         << "<div class=\"card\"><h2>Resource Map — Spice</h2>" << spice_map << "</div>\n"
         << "<div class=\"card\"><h2>Wealth Map</h2>" << wealth_map << "</div>\n"
         << "</div>\n</body></html>\n";

    const auto html_path = report_dir / "austrian_abm_report.html";
    std::ofstream out(html_path, std::ios::out | std::ios::trunc);
    out << html.str();
    std::printf("HTML report written to %s\n", html_path.string().c_str());
}

}  // namespace austrian_abm
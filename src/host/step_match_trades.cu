#include <algorithm>
#include <cstdio>
#include <vector>

#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "host/step_log.h"
#include "model/model_symbols.cuh"

namespace austrian_abm {

namespace {

struct TradeParticipant {
    unsigned int index = 0u;
    int agent_id = -1;
    float bid = 0.0f;
    float ask = 0.0f;
    int inventory = 0;
    float money = 0.0f;
};

bool TryExecuteTrade(
    flamegpu::DeviceAgentVector& population,
    const int good,
    std::vector<TradeParticipant>& buyers,
    std::vector<TradeParticipant>& sellers,
    unsigned int& trades_count,
    double& volume_sum,
    double& price_sum) {
    auto best_buy = std::max_element(buyers.begin(), buyers.end(),
        [](const TradeParticipant& a, const TradeParticipant& b) { return a.bid < b.bid; });
    auto best_sell = std::min_element(sellers.begin(), sellers.end(),
        [](const TradeParticipant& a, const TradeParticipant& b) {
            return a.ask > 0.0f && (b.ask <= 0.0f || a.ask < b.ask);
        });

    if (best_buy == buyers.end() || best_sell == sellers.end()) return false;
    if (best_buy->bid <= 0.0f || best_sell->ask <= 0.0f) return false;
    if (best_buy->bid < best_sell->ask) return false;
    if (best_buy->agent_id == best_sell->agent_id) return false;

    const float trade_price = 0.5f * (best_buy->bid + best_sell->ask);
    const unsigned int buyer_index = best_buy->index;
    const unsigned int seller_index = best_sell->index;

    float buyer_money = population[buyer_index].getVariable<float>("money");
    int buyer_sugar = population[buyer_index].getVariable<int>("sugar_level");
    int buyer_spice = population[buyer_index].getVariable<int>("spice_level");
    float seller_money = population[seller_index].getVariable<float>("money");
    int seller_sugar = population[seller_index].getVariable<int>("sugar_level");
    int seller_spice = population[seller_index].getVariable<int>("spice_level");

    if (buyer_money < trade_price) return false;

    buyer_money -= trade_price;
    seller_money += trade_price;

    if (good == kGoodSugar) {
        if (seller_sugar <= 0) return false;
        --seller_sugar;
        ++buyer_sugar;
    } else {
        if (seller_spice <= 0) return false;
        --seller_spice;
        ++buyer_spice;
    }

    population[buyer_index].setVariable<float>("money", buyer_money);
    population[buyer_index].setVariable<int>("sugar_level", buyer_sugar);
    population[buyer_index].setVariable<int>("spice_level", buyer_spice);
    population[seller_index].setVariable<float>("money", seller_money);
    population[seller_index].setVariable<int>("sugar_level", seller_sugar);
    population[seller_index].setVariable<int>("spice_level", seller_spice);

    ++trades_count;
    volume_sum += 1.0;
    price_sum += trade_price;

    best_buy->bid = 0.0f;
    best_buy->money = buyer_money;
    best_sell->ask = 0.0f;
    best_sell->inventory = good == kGoodSugar ? seller_sugar : seller_spice;
    return true;
}

void CollectParticipants(
    flamegpu::DeviceAgentVector& population,
    const int good,
    std::vector<TradeParticipant>& buyers,
    std::vector<TradeParticipant>& sellers) {
    buyers.clear();
    sellers.clear();
    for (unsigned int i = 0; i < population.size(); ++i) {
        const auto& cell = population[i];
        if (cell.getVariable<int>("status") != kAgentStatusOccupied) continue;
        TradeParticipant participant;
        participant.index = i;
        participant.agent_id = cell.getVariable<int>("agent_id");
        participant.money = cell.getVariable<float>("money");
        if (good == kGoodSugar) {
            participant.bid = cell.getVariable<float>("sugar_bid");
            participant.ask = cell.getVariable<float>("sugar_ask");
            participant.inventory = cell.getVariable<int>("sugar_level");
        } else {
            participant.bid = cell.getVariable<float>("spice_bid");
            participant.ask = cell.getVariable<float>("spice_ask");
            participant.inventory = cell.getVariable<int>("spice_level");
        }
        if (participant.bid > 0.0f) buyers.push_back(participant);
        if (participant.ask > 0.0f && participant.inventory > 0) sellers.push_back(participant);
    }
}

}  // namespace

FLAMEGPU_STEP_FUNCTION(MatchTrades) {
    flamegpu::DeviceAgentVector population = FLAMEGPU->agent("cell").getPopulationData();

    unsigned int trades_count = 0u;
    double volume_sum = 0.0;
    double price_sum = 0.0;
    float last_sugar_price = FLAMEGPU->environment.getProperty<float>("LAST_SUGAR_PRICE");
    float last_spice_price = FLAMEGPU->environment.getProperty<float>("LAST_SPICE_PRICE");

    std::vector<TradeParticipant> buyers;
    std::vector<TradeParticipant> sellers;

    for (const int good : {kGoodSugar, kGoodSpice}) {
        CollectParticipants(population, good, buyers, sellers);
        unsigned int good_trades = 0u;
        while (good_trades < 64u && TryExecuteTrade(population, good, buyers, sellers, trades_count, volume_sum, price_sum)) {
            ++good_trades;
            CollectParticipants(population, good, buyers, sellers);
        }
    }

    if (trades_count > 0u) {
        const float avg_price = static_cast<float>(price_sum / volume_sum);
        last_sugar_price = avg_price;
        last_spice_price = avg_price * 0.85f;
    }

    FLAMEGPU->environment.setProperty<unsigned int>("TRADES_COUNT", trades_count);
    FLAMEGPU->environment.setProperty<float>("TRADE_VOLUME", static_cast<float>(volume_sum));
    FLAMEGPU->environment.setProperty<float>("AVG_TRADE_PRICE", trades_count > 0u ? static_cast<float>(price_sum / volume_sum) : 0.0f);
    FLAMEGPU->environment.setProperty<float>("LAST_SUGAR_PRICE", last_sugar_price);
    FLAMEGPU->environment.setProperty<float>("LAST_SPICE_PRICE", last_spice_price);

    if (trades_count > 0u) {
        std::printf("trades=%u avg_price=%.4f volume=%.0f\n",
            trades_count, static_cast<float>(price_sum / volume_sum), volume_sum);
    }
}

FLAMEGPU_STEP_FUNCTION(LogMarketStep) {
    flamegpu::DeviceAgentVector population = FLAMEGPU->agent("cell").getPopulationData();
    long long total_sugar = 0;
    long long total_spice = 0;
    long long total_food = 0;
    unsigned int population_count = 0u;
    unsigned int production_count = 0u;
    unsigned int producer_count = 0u;
    for (const auto& cell : population) {
        if (cell.getVariable<int>("status") != kAgentStatusOccupied) continue;
        ++population_count;
        total_sugar += cell.getVariable<int>("sugar_level");
        total_spice += cell.getVariable<int>("spice_level");
        total_food += cell.getVariable<int>("food_level");
        if (cell.getVariable<int>("step_production") > 0) {
            ++production_count;
        }
        if (cell.getVariable<int>("activity_mode") == kActivityProduce) {
            ++producer_count;
        }
    }

    FLAMEGPU->environment.setProperty<unsigned int>("PRODUCTION_COUNT", production_count);
    FLAMEGPU->environment.setProperty<unsigned int>("PRODUCER_COUNT", producer_count);

    MarketStepMetrics metrics;
    metrics.step = FLAMEGPU->getStepCounter();
    metrics.avg_price = FLAMEGPU->environment.getProperty<float>("AVG_TRADE_PRICE");
    metrics.trades_count = FLAMEGPU->environment.getProperty<unsigned int>("TRADES_COUNT");
    metrics.trade_volume = FLAMEGPU->environment.getProperty<float>("TRADE_VOLUME");
    metrics.wealth_gini = ComputeWealthGini(population);
    metrics.population = population_count;
    metrics.total_sugar = total_sugar;
    metrics.total_spice = total_spice;
    metrics.total_food = total_food;
    metrics.production_count = production_count;
    metrics.producer_count = producer_count;
    AppendMarketHistory(metrics);

    if (production_count > 0u) {
        std::printf("production=%u producers=%u total_food=%lld\n",
            production_count, producer_count, total_food);
    }
}

}  // namespace austrian_abm
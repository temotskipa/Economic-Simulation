#include <algorithm>
#include <cstdio>
#include <vector>

#include "flamegpu/flamegpu.h"

#include "data/goods_catalog.cuh"
#include "domain/credit_functions.cuh"
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
    double& price_sum,
    float& trade_price_out) {
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
    float seller_money = population[seller_index].getVariable<float>("money");
    int buyer_qty = population[buyer_index].getVariable<int, kGoodCount>("inventory", good);
    int seller_qty = population[seller_index].getVariable<int, kGoodCount>("inventory", good);

    if (buyer_money < trade_price || seller_qty <= 0) return false;

    buyer_money -= trade_price;
    seller_money += trade_price;
    --seller_qty;
    ++buyer_qty;

    population[buyer_index].setVariable<float>("money", buyer_money);
    population[seller_index].setVariable<float>("money", seller_money);
    population[buyer_index].setVariable<int, kGoodCount>("inventory", good, buyer_qty);
    population[seller_index].setVariable<int, kGoodCount>("inventory", good, seller_qty);

    ++trades_count;
    volume_sum += 1.0;
    price_sum += trade_price;
    trade_price_out = trade_price;

    best_buy->bid = 0.0f;
    best_buy->money = buyer_money;
    best_sell->ask = 0.0f;
    best_sell->inventory = seller_qty;
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
        participant.bid = cell.getVariable<float, kGoodCount>("bid_price", good);
        participant.ask = cell.getVariable<float, kGoodCount>("ask_price", good);
        participant.inventory = cell.getVariable<int, kGoodCount>("inventory", good);
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
    double good_volume[kGoodCount] = {};
    double good_price_sum[kGoodCount] = {};

    std::vector<TradeParticipant> buyers;
    std::vector<TradeParticipant> sellers;

    for (int good = 0; good < kGoodCount; ++good) {
        if (!IsTradeableGood(good)) continue;
        CollectParticipants(population, good, buyers, sellers);
        unsigned int good_trades = 0u;
        float trade_price = 0.0f;
        while (good_trades < 32u && TryExecuteTrade(
            population, good, buyers, sellers, trades_count, volume_sum, price_sum, trade_price)) {
            ++good_trades;
            good_volume[good] += 1.0;
            good_price_sum[good] += trade_price;
            CollectParticipants(population, good, buyers, sellers);
        }
    }

    for (int good = 0; good < kGoodCount; ++good) {
        if (good_volume[good] > 0.0) {
            const float last_price = static_cast<float>(good_price_sum[good] / good_volume[good]);
            FLAMEGPU->environment.setProperty<float, kGoodCount>("LAST_PRICES", good, last_price);
        }
    }

    FLAMEGPU->environment.setProperty<unsigned int>("TRADES_COUNT", trades_count);
    FLAMEGPU->environment.setProperty<float>("TRADE_VOLUME", static_cast<float>(volume_sum));
    FLAMEGPU->environment.setProperty<float>("AVG_TRADE_PRICE", trades_count > 0u ? static_cast<float>(price_sum / volume_sum) : 0.0f);

    if (trades_count > 0u) {
        std::printf("trades=%u avg_price=%.4f volume=%.0f\n",
            trades_count, static_cast<float>(price_sum / volume_sum), volume_sum);
    }
}

FLAMEGPU_STEP_FUNCTION(LogMarketStep) {
    flamegpu::DeviceAgentVector population = FLAMEGPU->agent("cell").getPopulationData();
    long long total_grain = 0;
    long long total_fruit = 0;
    long long total_food = 0;
    long long total_capital = 0;
    long long total_intermediate = 0;
    long long total_res = 0;
    long long total_ind = 0;
    long long total_tech = 0;
    unsigned int population_count = 0u;
    unsigned int production_count = 0u;
    unsigned int producer_count = 0u;
    unsigned int investment_count = 0u;
    unsigned int roundabout_count = 0u;
    unsigned int capital_owner_count = 0u;
    unsigned int malinvestment_count = 0u;
    const unsigned int rate_suppressed =
        FLAMEGPU->environment.getProperty<unsigned int>("RATE_SUPPRESSED");
    for (const auto& cell : population) {
        if (cell.getVariable<int>("status") != kAgentStatusOccupied) continue;
        ++population_count;
        for (int good = 0; good < kGoodCount; ++good) {
            const long long qty = cell.getVariable<int, kGoodCount>("inventory", good);
            switch (GoodCategory(good)) {
                case kCategoryRes: total_res += qty; break;
                case kCategoryIndustrial: total_ind += qty; break;
                case kCategoryTech: total_tech += qty; break;
                default: break;
            }
        }
        total_grain += cell.getVariable<int, kGoodCount>("inventory", kGoodGrain);
        total_fruit += cell.getVariable<int, kGoodCount>("inventory", kGoodFruit);
        total_food += cell.getVariable<int, kGoodCount>("inventory", kGoodFood);
        total_intermediate += cell.getVariable<int, kGoodCount>("inventory", kGoodIntermediate);
        total_capital += cell.getVariable<int>("capital_stock");
        if (cell.getVariable<int>("step_production") > 0) {
            ++production_count;
        }
        if (cell.getVariable<int>("step_investment") > 0) {
            ++investment_count;
        }
        const int activity_mode = cell.getVariable<int>("activity_mode");
        if (activity_mode == kActivityProduce) {
            ++producer_count;
        } else if (activity_mode == kActivityRoundabout) {
            ++roundabout_count;
        }
        if (cell.getVariable<int>("is_capital_owner") > 0) {
            ++capital_owner_count;
        }
        if (IsMalinvestment(
                activity_mode,
                cell.getVariable<float>("loan_balance"),
                rate_suppressed)) {
            ++malinvestment_count;
        }
    }

    FLAMEGPU->environment.setProperty<unsigned int>("MALINVESTMENT_COUNT", malinvestment_count);
    FLAMEGPU->environment.setProperty<unsigned int>("PRODUCTION_COUNT", production_count);
    FLAMEGPU->environment.setProperty<unsigned int>("PRODUCER_COUNT", producer_count);
    FLAMEGPU->environment.setProperty<unsigned int>("INVESTMENT_COUNT", investment_count);
    FLAMEGPU->environment.setProperty<unsigned int>("ROUNDABOUT_COUNT", roundabout_count);
    FLAMEGPU->environment.setProperty<long long>("TOTAL_CAPITAL", total_capital);

    MarketStepMetrics metrics;
    metrics.step = FLAMEGPU->getStepCounter();
    metrics.avg_price = FLAMEGPU->environment.getProperty<float>("AVG_TRADE_PRICE");
    metrics.trades_count = FLAMEGPU->environment.getProperty<unsigned int>("TRADES_COUNT");
    metrics.trade_volume = FLAMEGPU->environment.getProperty<float>("TRADE_VOLUME");
    metrics.wealth_gini = ComputeWealthGini(population);
    metrics.population = population_count;
    metrics.total_sugar = total_grain;
    metrics.total_spice = total_fruit;
    metrics.total_food = total_food;
    metrics.production_count = production_count;
    metrics.producer_count = producer_count;
    metrics.total_capital = total_capital;
    metrics.total_intermediate = total_intermediate;
    metrics.total_res = total_res;
    metrics.total_ind = total_ind;
    metrics.total_tech = total_tech;
    metrics.investment_count = investment_count;
    metrics.roundabout_count = roundabout_count;
    metrics.capital_owner_count = capital_owner_count;
    metrics.credit_created = FLAMEGPU->environment.getProperty<unsigned int>("CREDIT_CREATED");
    metrics.total_loans = FLAMEGPU->environment.getProperty<float>("TOTAL_LOANS");
    metrics.effective_rate = FLAMEGPU->environment.getProperty<float>("EFFECTIVE_RATE");
    metrics.rate_suppressed = rate_suppressed;
    metrics.malinvestment_count = malinvestment_count;
    AppendMarketHistory(metrics);

    if (production_count > 0u || investment_count > 0u || metrics.credit_created > 0u) {
        std::printf(
            "production=%u res=%lld ind=%lld tech=%lld credit=%u rate=%.4f\n",
            production_count, total_res, total_ind, total_tech,
            metrics.credit_created, metrics.effective_rate);
    }
}

}  // namespace austrian_abm
#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "domain/trade_functions.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DEF(OutputTradeOffers, flamegpu::MessageNone, flamegpu::MessageBruteForce) {
    const int status = FLAMEGPU->getVariable<int>("status");
    if (status != kAgentStatusOccupied) {
        FLAMEGPU->setVariable<float>("sugar_bid", 0.0f);
        FLAMEGPU->setVariable<float>("sugar_ask", 0.0f);
        FLAMEGPU->setVariable<float>("spice_bid", 0.0f);
        FLAMEGPU->setVariable<float>("spice_ask", 0.0f);
        return flamegpu::ALIVE;
    }

    const int sugar_level = FLAMEGPU->getVariable<int>("sugar_level");
    const int spice_level = FLAMEGPU->getVariable<int>("spice_level");
    const float money = FLAMEGPU->getVariable<float>("money");
    const float sugar_price = FLAMEGPU->environment.getProperty<float>("LAST_SUGAR_PRICE");
    const float spice_price = FLAMEGPU->environment.getProperty<float>("LAST_SPICE_PRICE");

    const float mu_sugar = MarginalUtilitySugar(sugar_level, spice_level);
    const float mu_spice = MarginalUtilitySpice(sugar_level, spice_level);
    const float sugar_bid = ReservationBidPrice(money, mu_sugar, mu_spice);
    const float spice_bid = ReservationBidPrice(money, mu_spice, mu_sugar);
    const float sugar_ask = ReservationAskPrice(sugar_level, mu_sugar, sugar_price);
    const float spice_ask = ReservationAskPrice(spice_level, mu_spice, spice_price);

    FLAMEGPU->setVariable<float>("sugar_bid", sugar_bid);
    FLAMEGPU->setVariable<float>("sugar_ask", sugar_ask);
    FLAMEGPU->setVariable<float>("spice_bid", spice_bid);
    FLAMEGPU->setVariable<float>("spice_ask", spice_ask);

    const int agent_id = FLAMEGPU->getVariable<int>("agent_id");
    float best_price = 0.0f;
    int best_good = kGoodSugar;
    int best_side = kTradeBid;
    if (sugar_bid > best_price) {
        best_price = sugar_bid;
        best_good = kGoodSugar;
        best_side = kTradeBid;
    }
    if (sugar_ask > best_price) {
        best_price = sugar_ask;
        best_good = kGoodSugar;
        best_side = kTradeAsk;
    }
    if (spice_bid > best_price) {
        best_price = spice_bid;
        best_good = kGoodSpice;
        best_side = kTradeBid;
    }
    if (spice_ask > best_price) {
        best_price = spice_ask;
        best_good = kGoodSpice;
        best_side = kTradeAsk;
    }
    if (best_price > 0.0f) {
        FLAMEGPU->message_out.setVariable<int>("agent_id", agent_id);
        FLAMEGPU->message_out.setVariable<int>("good", best_good);
        FLAMEGPU->message_out.setVariable<int>("side", best_side);
        FLAMEGPU->message_out.setVariable<float>("price", best_price);
        FLAMEGPU->message_out.setVariable<int>("quantity", 1);
    }

    return flamegpu::ALIVE;
}

}  // namespace austrian_abm
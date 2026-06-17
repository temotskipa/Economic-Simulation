#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "data/goods_catalog.cuh"
#include "domain/inventory.cuh"
#include "domain/trade_functions.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DEF(OutputTradeOffers, flamegpu::MessageNone, flamegpu::MessageBruteForce) {
    const int status = FLAMEGPU->getVariable<int>("status");
    if (status != kAgentStatusOccupied) {
        for (int good = 0; good < kGoodCount; ++good) {
            BidPriceSet(FLAMEGPU, good, 0.0f);
            AskPriceSet(FLAMEGPU, good, 0.0f);
        }
        return flamegpu::ALIVE;
    }

    const float money = FLAMEGPU->getVariable<float>("money");
    const int grain = InventoryGet(FLAMEGPU, kGoodGrain);
    const int fruit = InventoryGet(FLAMEGPU, kGoodFruit);

    float best_price = 0.0f;
    int best_good = kGoodGrain;
    int best_side = kTradeBid;

    for (int good = 0; good < kGoodCount; ++good) {
        if (!IsTradeableGood(good)) continue;
        const int held = InventoryGet(FLAMEGPU, good);
        const int peer = (good == kGoodGrain) ? fruit : grain;
        const float market_hint = FLAMEGPU->environment.getProperty<float, kGoodCount>("LAST_PRICES", good);
        const float mu = MarginalUtilityForGood(good, held, peer);
        const float bid = ReservationBidPrice(money, mu, MarginalUtilityForGood(
            good == kGoodGrain ? kGoodFruit : kGoodGrain, peer, held));
        const float ask = ReservationAskPrice(held, mu, market_hint);
        BidPriceSet(FLAMEGPU, good, bid);
        AskPriceSet(FLAMEGPU, good, ask);

        if (bid > best_price) {
            best_price = bid;
            best_good = good;
            best_side = kTradeBid;
        }
        if (ask > best_price) {
            best_price = ask;
            best_good = good;
            best_side = kTradeAsk;
        }
    }

    if (best_price > 0.0f) {
        FLAMEGPU->message_out.setVariable<int>("agent_id", FLAMEGPU->getVariable<int>("agent_id"));
        FLAMEGPU->message_out.setVariable<int>("good", best_good);
        FLAMEGPU->message_out.setVariable<int>("side", best_side);
        FLAMEGPU->message_out.setVariable<float>("price", best_price);
        FLAMEGPU->message_out.setVariable<int>("quantity", 1);
    }

    return flamegpu::ALIVE;
}

}  // namespace austrian_abm
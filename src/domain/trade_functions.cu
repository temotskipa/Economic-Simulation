#include "flamegpu/flamegpu.h"

#include "data/catalog_env.cuh"
#include "data/constants.cuh"
#include "data/goods_catalog.cuh"
#include "domain/inventory.cuh"
#include "domain/trade_functions.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DEF(OutputTradeOffers, flamegpu::MessageNone, flamegpu::MessageSpatial2D) {
    const int status = FLAMEGPU->getVariable<int>("status");
    const unsigned int good_count = CatalogGoodCount(FLAMEGPU);
    if (status != kAgentStatusOccupied) {
        for (unsigned int good = 0u; good < good_count; ++good) {
            BidPriceSet(FLAMEGPU, static_cast<int>(good), 0.0f);
            AskPriceSet(FLAMEGPU, static_cast<int>(good), 0.0f);
        }
        return flamegpu::ALIVE;
    }

    const float money = FLAMEGPU->getVariable<float>("money");

    float best_price = 0.0f;
    int best_good = kGoodGrain;
    int best_side = kTradeBid;

    for (unsigned int good = 0u; good < good_count; ++good) {
        const int good_id = static_cast<int>(good);
        if (!CatalogIsTradeable(FLAMEGPU, good_id)) continue;
        const int held = InventoryGet(FLAMEGPU, good_id);
        const int complement = CatalogGoodComplement(FLAMEGPU, good_id);
        const int peer = complement >= 0 ? InventoryGet(FLAMEGPU, complement) : 0;
        const float utility = CatalogGoodUtility(FLAMEGPU, good_id);
        const float market_hint =
            FLAMEGPU->environment.getProperty<float, kMaxGoods>("LAST_PRICES", good_id);
        const float mu = MarginalUtilityForGood(utility, held, peer);
        float mrs_peer = 0.01f;
        if (complement >= 0) {
            const float complement_utility = CatalogGoodUtility(FLAMEGPU, complement);
            mrs_peer = MarginalUtilityForGood(complement_utility, peer, held);
        }
        const float bid = ReservationBidPrice(money, mu, mrs_peer);
        const float ask = ReservationAskPrice(held, mu, market_hint);
        BidPriceSet(FLAMEGPU, good_id, bid);
        AskPriceSet(FLAMEGPU, good_id, ask);

        if (bid > best_price) {
            best_price = bid;
            best_good = good_id;
            best_side = kTradeBid;
        }
        if (ask > best_price) {
            best_price = ask;
            best_good = good_id;
            best_side = kTradeAsk;
        }
    }

    if (best_price > 0.0f) {
        FLAMEGPU->message_out.setVariable<int>("agent_id", FLAMEGPU->getVariable<int>("agent_id"));
        FLAMEGPU->message_out.setVariable<int>("good", best_good);
        FLAMEGPU->message_out.setVariable<int>("side", best_side);
        FLAMEGPU->message_out.setVariable<float>("price", best_price);
        FLAMEGPU->message_out.setVariable<int>("quantity", 1);
        FLAMEGPU->message_out.setLocation(
            static_cast<float>(FLAMEGPU->getVariable<unsigned int, 2>("pos", 0)),
            static_cast<float>(FLAMEGPU->getVariable<unsigned int, 2>("pos", 1)));
    }

    return flamegpu::ALIVE;
}

FLAMEGPU_AGENT_FUNCTION_DEF(ScanSpatialArbitrage, flamegpu::MessageSpatial2D, flamegpu::MessageNone) {
    const int status = FLAMEGPU->getVariable<int>("status");
    if (status != kAgentStatusOccupied) {
        FLAMEGPU->setVariable<int>("arbitrage_signals", 0);
        return flamegpu::ALIVE;
    }

    const int self_id = FLAMEGPU->getVariable<int>("agent_id");
    const float agent_x = static_cast<float>(FLAMEGPU->getVariable<unsigned int, 2>("pos", 0));
    const float agent_y = static_cast<float>(FLAMEGPU->getVariable<unsigned int, 2>("pos", 1));
    int signals = 0;

    for (const auto& offer : FLAMEGPU->message_in(agent_x, agent_y)) {
        const int offer_agent = offer.getVariable<int>("agent_id");
        if (offer_agent == self_id) continue;
        const int good = offer.getVariable<int>("good");
        const int side = offer.getVariable<int>("side");
        const float price = offer.getVariable<float>("price");
        if (good < 0 || static_cast<unsigned int>(good) >= CatalogGoodCount(FLAMEGPU)) continue;
        if (!CatalogIsTradeable(FLAMEGPU, good)) continue;

        const float bid = BidPriceGet(FLAMEGPU, good);
        const float ask = AskPriceGet(FLAMEGPU, good);
        if (side == kTradeAsk && bid > price) {
            ++signals;
        } else if (side == kTradeBid && ask > 0.0f && ask < price
            && InventoryGet(FLAMEGPU, good) > 0) {
            ++signals;
        }
    }

    FLAMEGPU->setVariable<int>("arbitrage_signals", signals);
    return flamegpu::ALIVE;
}

}  // namespace austrian_abm
#pragma once

#include "data/goods_catalog.cuh"

namespace austrian_abm {

#define InventoryGet(api, good) ((api)->getVariable<int, kGoodCount>("inventory", (good)))
#define InventorySet(api, good, amount) ((api)->setVariable<int, kGoodCount>("inventory", (good), (amount)))
#define InventoryAdd(api, good, delta) InventorySet((api), (good), InventoryGet((api), (good)) + (delta))
#define BidPriceGet(api, good) ((api)->getVariable<float, kGoodCount>("bid_price", (good)))
#define BidPriceSet(api, good, price) ((api)->setVariable<float, kGoodCount>("bid_price", (good), (price)))
#define AskPriceGet(api, good) ((api)->getVariable<float, kGoodCount>("ask_price", (good)))
#define AskPriceSet(api, good, price) ((api)->setVariable<float, kGoodCount>("ask_price", (good), (price)))

}  // namespace austrian_abm
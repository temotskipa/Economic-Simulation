#pragma once

#include "data/goods_catalog.cuh"
#include "domain/inventory.cuh"

namespace austrian_abm {

#define CatalogGoodCount(api) ((api)->environment.getProperty<unsigned int>("GOOD_COUNT"))
#define CatalogGoodCategory(api, g) ((api)->environment.getProperty<int, kMaxGoods>("GOOD_CATEGORY", (g)))
#define CatalogGoodUtility(api, g) ((api)->environment.getProperty<float, kMaxGoods>("GOOD_UTILITY", (g)))
#define CatalogGoodFlags(api, g) ((api)->environment.getProperty<unsigned int, kMaxGoods>("GOOD_FLAGS", (g)))
#define CatalogGoodComplement(api, g) ((api)->environment.getProperty<int, kMaxGoods>("GOOD_COMPLEMENT", (g)))
#define CatalogIsTradeable(api, g) ((CatalogGoodFlags((api), (g)) & kGoodFlagTradeable) != 0u)

#define CatalogRecipeCount(api) ((api)->environment.getProperty<unsigned int>("RECIPE_COUNT"))
#define CatalogRecipeOutputGood(api, i) ((api)->environment.getProperty<int, kMaxRecipes>("RECIPE_OUTPUT_GOOD", (i)))
#define CatalogRecipeOutputQty(api, i) ((api)->environment.getProperty<int, kMaxRecipes>("RECIPE_OUTPUT_QTY", (i)))
#define CatalogRecipeInput0Good(api, i) ((api)->environment.getProperty<int, kMaxRecipes>("RECIPE_INPUT0_GOOD", (i)))
#define CatalogRecipeInput0Qty(api, i) ((api)->environment.getProperty<int, kMaxRecipes>("RECIPE_INPUT0_QTY", (i)))
#define CatalogRecipeInput1Good(api, i) ((api)->environment.getProperty<int, kMaxRecipes>("RECIPE_INPUT1_GOOD", (i)))
#define CatalogRecipeInput1Qty(api, i) ((api)->environment.getProperty<int, kMaxRecipes>("RECIPE_INPUT1_QTY", (i)))
#define CatalogRecipeMinSkill(api, i) ((api)->environment.getProperty<float, kMaxRecipes>("RECIPE_MIN_SKILL", (i)))
#define CatalogRecipeActivity(api, i) ((api)->environment.getProperty<int, kMaxRecipes>("RECIPE_ACTIVITY", (i)))

#define CatalogRoundaboutOutputGood(api, i) \
    ((api)->environment.getProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_OUTPUT_GOOD", (i)))
#define CatalogRoundaboutOutputQty(api, i) \
    ((api)->environment.getProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_OUTPUT_QTY", (i)))
#define CatalogRoundaboutInput0Good(api, i) \
    ((api)->environment.getProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_INPUT0_GOOD", (i)))
#define CatalogRoundaboutInput0Qty(api, i) \
    ((api)->environment.getProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_INPUT0_QTY", (i)))
#define CatalogRoundaboutInput1Good(api, i) \
    ((api)->environment.getProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_INPUT1_GOOD", (i)))
#define CatalogRoundaboutInput1Qty(api, i) \
    ((api)->environment.getProperty<int, kMaxRoundaboutRecipes>("ROUNDABOUT_INPUT1_QTY", (i)))

#define CatalogInstantRecipeHasInputs(api, idx) ( \
    (CatalogRecipeInput0Good((api), (idx)) < 0 \
        || InventoryGet((api), CatalogRecipeInput0Good((api), (idx))) \
            >= CatalogRecipeInput0Qty((api), (idx))) \
    && (CatalogRecipeInput1Good((api), (idx)) < 0 \
        || InventoryGet((api), CatalogRecipeInput1Good((api), (idx))) \
            >= CatalogRecipeInput1Qty((api), (idx))))

#define CatalogInstantRecipeApply(api, idx) do { \
    const int _in0g = CatalogRecipeInput0Good((api), (idx)); \
    const int _in1g = CatalogRecipeInput1Good((api), (idx)); \
    if (_in0g >= 0) { \
        InventoryAdd((api), _in0g, -CatalogRecipeInput0Qty((api), (idx))); \
    } \
    if (_in1g >= 0) { \
        InventoryAdd((api), _in1g, -CatalogRecipeInput1Qty((api), (idx))); \
    } \
    InventoryAdd((api), CatalogRecipeOutputGood((api), (idx)), CatalogRecipeOutputQty((api), (idx))); \
} while (0)

#define CatalogRoundaboutRecipeHasInputs(api, idx) ( \
    (CatalogRoundaboutInput0Good((api), (idx)) < 0 \
        || InventoryGet((api), CatalogRoundaboutInput0Good((api), (idx))) \
            >= CatalogRoundaboutInput0Qty((api), (idx))) \
    && (CatalogRoundaboutInput1Good((api), (idx)) < 0 \
        || InventoryGet((api), CatalogRoundaboutInput1Good((api), (idx))) \
            >= CatalogRoundaboutInput1Qty((api), (idx))))

#define CatalogRoundaboutRecipeApply(api, idx) do { \
    const int _rb_in0g = CatalogRoundaboutInput0Good((api), (idx)); \
    const int _rb_in1g = CatalogRoundaboutInput1Good((api), (idx)); \
    if (_rb_in0g >= 0) { \
        InventoryAdd((api), _rb_in0g, -CatalogRoundaboutInput0Qty((api), (idx))); \
    } \
    if (_rb_in1g >= 0) { \
        InventoryAdd((api), _rb_in1g, -CatalogRoundaboutInput1Qty((api), (idx))); \
    } \
    InventoryAdd((api), CatalogRoundaboutOutputGood((api), (idx)), CatalogRoundaboutOutputQty((api), (idx))); \
} while (0)

}  // namespace austrian_abm
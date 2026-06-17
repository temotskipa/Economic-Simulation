#pragma once

namespace austrian_abm {

// Vic3-inspired categories
constexpr int kCategoryRes = 0;
constexpr int kCategoryStaple = 1;
constexpr int kCategoryIndustrial = 2;
constexpr int kCategoryTech = 3;

// Tradeable & producible goods (Sugarscape grain/fruit retained as patch resources)
constexpr int kGoodGrain = 0;        // Vic3 grain (sugarscape sugar patch)
constexpr int kGoodFruit = 1;        // Vic3 fruit (sugarscape spice patch)
constexpr int kGoodFood = 2;           // staple
constexpr int kGoodIntermediate = 3;   // roundabout intermediate
constexpr int kGoodIron = 4;         // RES
constexpr int kGoodCoal = 5;         // RES
constexpr int kGoodWood = 6;         // RES
constexpr int kGoodTools = 7;        // IND
constexpr int kGoodSteel = 8;        // IND
constexpr int kGoodEngines = 9;      // TECH
constexpr int kGoodElectricity = 10;   // TECH (abstract)
constexpr int kGoodCount = 11;

// Backward-compatible aliases used in older code paths
constexpr int kGoodSugar = kGoodGrain;
constexpr int kGoodSpice = kGoodFruit;

constexpr int kPatchGoodCount = 4;  // env patch slots: grain, fruit, iron, coal

constexpr int GoodCategory(const int good) {
    switch (good) {
        case kGoodGrain: case kGoodFruit: case kGoodIron: case kGoodCoal: case kGoodWood:
            return kCategoryRes;
        case kGoodFood:
            return kCategoryStaple;
        case kGoodTools: case kGoodSteel: case kGoodIntermediate:
            return kCategoryIndustrial;
        case kGoodEngines: case kGoodElectricity:
            return kCategoryTech;
        default:
            return kCategoryRes;
    }
}

constexpr bool IsTradeableGood(const int good) {
    return good >= 0 && good < kGoodCount && good != kGoodElectricity;
}

constexpr float GoodUtilityWeight(const int good) {
    switch (good) {
        case kGoodGrain: return 1.0f;
        case kGoodFruit: return 1.0f;
        case kGoodFood: return 1.5f;
        case kGoodIntermediate: return 1.2f;
        case kGoodIron: return 1.1f;
        case kGoodCoal: return 1.0f;
        case kGoodWood: return 0.9f;
        case kGoodTools: return 1.4f;
        case kGoodSteel: return 1.5f;
        case kGoodEngines: return 2.0f;
        case kGoodElectricity: return 2.2f;
        default: return 1.0f;
    }
}

constexpr float GoodWealthValue(const int good) {
    return GoodUtilityWeight(good);
}

}  // namespace austrian_abm
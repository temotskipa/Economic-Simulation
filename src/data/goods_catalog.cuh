#pragma once

namespace austrian_abm {

constexpr int kCategoryRes = 0;
constexpr int kCategoryStaple = 1;
constexpr int kCategoryIndustrial = 2;
constexpr int kCategoryTech = 3;
constexpr int kCategorySvcTransport = 4;
constexpr int kCategorySvcConstruction = 5;
constexpr int kCategorySvcClerical = 6;
constexpr int kCategorySvcHealth = 7;
constexpr int kCategorySvcEducation = 8;

constexpr int kKindGood = 0;
constexpr int kKindService = 1;

constexpr int kMaxGoods = 24;
constexpr int kMaxRecipes = 24;
constexpr int kMaxRoundaboutRecipes = 4;
constexpr int kGoodCount = kMaxGoods;

constexpr unsigned int kGoodFlagTradeable = 1u;

constexpr int kRecipeAnyActivity = -1;
constexpr int kNoRecipeInput = -1;
constexpr int kNoComplementGood = -1;

// Stable indices — goods[] then services[] order in vic3_catalog.json.
constexpr int kGoodGrain = 0;
constexpr int kGoodFruit = 1;
constexpr int kGoodFood = 2;
constexpr int kGoodIntermediate = 3;
constexpr int kGoodIron = 4;
constexpr int kGoodCoal = 5;
constexpr int kGoodWood = 6;
constexpr int kGoodTools = 7;
constexpr int kGoodSteel = 8;
constexpr int kGoodEngines = 9;
constexpr int kGoodElectricity = 10;
constexpr int kGoodFabric = 11;
constexpr int kGoodGlass = 12;
constexpr int kGoodFertilizer = 13;
constexpr int kGoodRubber = 14;

constexpr int kSvcTransport = 15;
constexpr int kSvcConstruction = 16;
constexpr int kSvcClerical = 17;
constexpr int kSvcHealthcare = 18;
constexpr int kSvcEducation = 19;

constexpr int kGoodSugar = kGoodGrain;
constexpr int kGoodSpice = kGoodFruit;

constexpr int kPatchGoodCount = 4;

}  // namespace austrian_abm
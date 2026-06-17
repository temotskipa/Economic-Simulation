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

constexpr int kMaxGoods = 32;
constexpr int kMaxRecipes = 32;
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
constexpr int kGoodPaper = 15;
constexpr int kGoodLiquor = 16;
constexpr int kGoodLivestock = 17;
constexpr int kGoodMeat = 18;
constexpr int kGoodFish = 19;
constexpr int kGoodSilk = 20;
constexpr int kGoodDyes = 21;
constexpr int kGoodPorcelain = 22;
constexpr int kGoodCoffee = 23;
constexpr int kGoodOil = 24;

constexpr int kSvcTransport = 25;
constexpr int kSvcConstruction = 26;
constexpr int kSvcClerical = 27;
constexpr int kSvcHealthcare = 28;
constexpr int kSvcEducation = 29;

constexpr int kGoodSugar = kGoodGrain;
constexpr int kGoodSpice = kGoodFruit;

constexpr int kPatchGoodCount = 4;

}  // namespace austrian_abm
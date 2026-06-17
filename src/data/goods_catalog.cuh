#pragma once

namespace austrian_abm {

constexpr int kCategoryRes = 0;
constexpr int kCategoryStaple = 1;
constexpr int kCategoryIndustrial = 2;
constexpr int kCategoryTech = 3;

constexpr int kMaxGoods = 16;
constexpr int kMaxRecipes = 16;
constexpr int kMaxRoundaboutRecipes = 4;
constexpr int kGoodCount = kMaxGoods;

constexpr unsigned int kGoodFlagTradeable = 1u;

constexpr int kRecipeAnyActivity = -1;
constexpr int kNoRecipeInput = -1;
constexpr int kNoComplementGood = -1;

// Stable indices — must match goods[] order in vic3_catalog.json.
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

constexpr int kGoodSugar = kGoodGrain;
constexpr int kGoodSpice = kGoodFruit;

constexpr int kPatchGoodCount = 4;

}  // namespace austrian_abm
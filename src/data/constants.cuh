#pragma once

namespace austrian_abm {

constexpr char kModelName[] = "Austrian ABM Sugarscape";

constexpr unsigned int kDefaultGridWidth = 224u;
constexpr unsigned int kDefaultGridHeight = 224u;
constexpr unsigned int kDefaultSteps = 12u;
constexpr unsigned int kDefaultSeed = 42u;
constexpr float kDefaultOccupancy = 0.1f;
constexpr float kDefaultInitialMoney = 100.0f;
constexpr unsigned int kDefaultGoodStages = 2u;

constexpr int kAgentStatusUnoccupied = 0;
constexpr int kAgentStatusOccupied = 1;
constexpr int kAgentStatusMovementRequested = 2;
constexpr int kAgentStatusMovementUnresolved = 3;

constexpr int kSugarGrowbackRate = 1;
constexpr int kSpiceGrowbackRate = 1;
constexpr int kSugarMaxCapacity = 7;
constexpr int kSpiceMaxCapacity = 7;
constexpr int kDefaultMetabolism = 6;

constexpr int kGoodSugar = 0;
constexpr int kGoodSpice = 1;
constexpr int kGoodFood = 2;
constexpr int kTradeBid = 0;
constexpr int kTradeAsk = 1;

constexpr int kActivityHarvest = 0;
constexpr int kActivityProduce = 1;

constexpr int kFoodRecipeSugar = 1;
constexpr int kFoodRecipeSpice = 1;
constexpr int kFoodMetabolismValue = 3;
constexpr float kFoodValueMultiplier = 1.5f;
constexpr float kMinProductionSkill = 0.3f;
constexpr float kMaxProductionSkill = 1.0f;

constexpr int kActivityRoundabout = 2;
constexpr int kActivityInvest = 3;

constexpr int kProductionStageIdle = 0;
constexpr int kProductionStageIntermediate = 1;
constexpr int kProductionStageFinal = 2;

constexpr int kIntermediateRecipeSugar = 1;
constexpr int kIntermediateRecipeSpice = 1;
constexpr int kFinalRecipeIntermediate = 1;

constexpr int kDirectProductionPeriod = 1;
constexpr int kRoundaboutIntermediatePeriod = 2;
constexpr int kRoundaboutFinalPeriod = 3;

constexpr float kCapitalEfficiencyPerUnit = 0.75f;
constexpr float kCapitalUnitCost = 25.0f;
constexpr float kCapitalValuePerUnit = 30.0f;
constexpr float kRoundaboutFoodMultiplier = 2.0f;
constexpr float kMinTimePreference = 0.02f;
constexpr float kMaxTimePreference = 0.35f;
constexpr float kCapitalOwnerMaxTimePreference = 0.15f;

}  // namespace austrian_abm
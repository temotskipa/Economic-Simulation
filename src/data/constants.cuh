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

constexpr int kTradeBid = 0;
constexpr int kTradeAsk = 1;

constexpr int kIronGrowbackRate = 1;
constexpr int kCoalGrowbackRate = 1;
constexpr int kIronMaxCapacity = 5;
constexpr int kCoalMaxCapacity = 5;

constexpr int kActivityHarvest = 0;
constexpr int kActivityProduce = 1;

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

constexpr unsigned int kDefaultBankCount = 4u;
constexpr float kBankInitialReserves = 5000.0f;
constexpr float kReserveLendingMultiplier = 4.0f;
constexpr float kDefaultNaturalRate = 0.08f;
constexpr float kDefaultPolicyRate = 0.02f;
constexpr unsigned int kDefaultRateShockStep = 6u;
constexpr float kDefaultLoanSize = 40.0f;
constexpr float kMaxLoanBalance = 120.0f;
constexpr float kDepositThreshold = 50.0f;
constexpr float kDepositFraction = 0.3f;
constexpr float kEntrepreneurMinSkill = 0.45f;

constexpr int kMaxRegions = 4;
constexpr float kDefaultTradeRadius = 24.0f;

}  // namespace austrian_abm
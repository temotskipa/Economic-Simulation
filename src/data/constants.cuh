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
constexpr int kTradeBid = 0;
constexpr int kTradeAsk = 1;

}  // namespace austrian_abm
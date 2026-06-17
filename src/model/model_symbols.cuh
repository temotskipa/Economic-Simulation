#pragma once

#include "flamegpu/flamegpu.h"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DECL(MetaboliseAndGrowback, flamegpu::MessageNone, flamegpu::MessageNone);
FLAMEGPU_AGENT_FUNCTION_DECL(OutputCellStatus, flamegpu::MessageNone, flamegpu::MessageArray2D);
FLAMEGPU_AGENT_FUNCTION_DECL(MovementRequest, flamegpu::MessageArray2D, flamegpu::MessageArray2D);
FLAMEGPU_AGENT_FUNCTION_DECL(MovementResponse, flamegpu::MessageArray2D, flamegpu::MessageArray2D);
FLAMEGPU_AGENT_FUNCTION_DECL(MovementTransaction, flamegpu::MessageArray2D, flamegpu::MessageNone);
FLAMEGPU_AGENT_FUNCTION_DECL(ChooseProductionActivity, flamegpu::MessageNone, flamegpu::MessageNone);
FLAMEGPU_AGENT_FUNCTION_DECL(InvestCapital, flamegpu::MessageNone, flamegpu::MessageNone);
FLAMEGPU_AGENT_FUNCTION_DECL(AdvanceRoundaboutProduction, flamegpu::MessageNone, flamegpu::MessageNone);
FLAMEGPU_AGENT_FUNCTION_DECL(ProduceFood, flamegpu::MessageNone, flamegpu::MessageNone);
FLAMEGPU_AGENT_FUNCTION_DECL(ProduceIndustrialGoods, flamegpu::MessageNone, flamegpu::MessageNone);
FLAMEGPU_AGENT_FUNCTION_DECL(OutputTradeOffers, flamegpu::MessageNone, flamegpu::MessageBruteForce);

extern flamegpu::FLAMEGPU_EXIT_CONDITION_POINTER MovementExitCondition;

FLAMEGPU_HOST_FUNCTION_DECL(SeedGrid);
FLAMEGPU_HOST_FUNCTION_DECL(SeedBanks);
FLAMEGPU_HOST_FUNCTION_DECL(ProcessBanking);
FLAMEGPU_HOST_FUNCTION_DECL(MatchTrades);
FLAMEGPU_HOST_FUNCTION_DECL(LogMarketStep);

}  // namespace austrian_abm
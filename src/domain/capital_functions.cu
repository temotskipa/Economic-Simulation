#include "flamegpu/flamegpu.h"

#include "data/catalog_env.cuh"
#include "data/constants.cuh"
#include "data/goods_catalog.cuh"
#include "domain/capital_functions.cuh"
#include "domain/inventory.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DEF(InvestCapital, flamegpu::MessageNone, flamegpu::MessageNone) {
    const int status = FLAMEGPU->getVariable<int>("status");
    if (status != kAgentStatusOccupied) return flamegpu::ALIVE;
    if (FLAMEGPU->getVariable<int>("activity_mode") != kActivityInvest) return flamegpu::ALIVE;

    float money = FLAMEGPU->getVariable<float>("money");
    if (money < kCapitalUnitCost) return flamegpu::ALIVE;

    money -= kCapitalUnitCost;
    const int capital_stock = FLAMEGPU->getVariable<int>("capital_stock") + 1;
    FLAMEGPU->setVariable<float>("money", money);
    FLAMEGPU->setVariable<int>("capital_stock", capital_stock);
    FLAMEGPU->setVariable<int>("is_capital_owner", 1);
    FLAMEGPU->setVariable<int>("step_investment", 1);
    return flamegpu::ALIVE;
}

FLAMEGPU_AGENT_FUNCTION_DEF(AdvanceRoundaboutProduction, flamegpu::MessageNone, flamegpu::MessageNone) {
    const int status = FLAMEGPU->getVariable<int>("status");
    if (status != kAgentStatusOccupied) return flamegpu::ALIVE;
    if (FLAMEGPU->getVariable<int>("activity_mode") != kActivityRoundabout) return flamegpu::ALIVE;

    int production_stage = FLAMEGPU->getVariable<int>("production_stage");
    int stage_progress = FLAMEGPU->getVariable<int>("stage_progress");
    const int capital_stock = FLAMEGPU->getVariable<int>("capital_stock");

    if (production_stage == kProductionStageIdle) {
        production_stage = kProductionStageIntermediate;
        stage_progress = 0;
    }

    if (production_stage == kProductionStageIntermediate) {
        const int period = EffectiveProductionPeriod(kRoundaboutIntermediatePeriod, capital_stock);
        ++stage_progress;
        if (stage_progress >= period) {
            if (!CatalogRoundaboutRecipeHasInputs(FLAMEGPU, 0)) {
                production_stage = kProductionStageIdle;
                stage_progress = 0;
            } else {
                CatalogRoundaboutRecipeApply(FLAMEGPU, 0);
                production_stage = kProductionStageFinal;
                stage_progress = 0;
            }
        }
    } else if (production_stage == kProductionStageFinal) {
        const int period = EffectiveProductionPeriod(kRoundaboutFinalPeriod, capital_stock);
        ++stage_progress;
        if (stage_progress >= period) {
            if (!CatalogRoundaboutRecipeHasInputs(FLAMEGPU, 1)) {
                production_stage = kProductionStageIdle;
                stage_progress = 0;
            } else {
                CatalogRoundaboutRecipeApply(FLAMEGPU, 1);
                FLAMEGPU->setVariable<int>("step_production", 1);
                production_stage = kProductionStageIdle;
                stage_progress = 0;
            }
        }
    }

    FLAMEGPU->setVariable<int>("production_stage", production_stage);
    FLAMEGPU->setVariable<int>("stage_progress", stage_progress);
    return flamegpu::ALIVE;
}

}  // namespace austrian_abm
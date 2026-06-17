#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "domain/capital_functions.cuh"
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
            int sugar_level = FLAMEGPU->getVariable<int>("sugar_level");
            int spice_level = FLAMEGPU->getVariable<int>("spice_level");
            if (sugar_level < kIntermediateRecipeSugar || spice_level < kIntermediateRecipeSpice) {
                production_stage = kProductionStageIdle;
                stage_progress = 0;
            } else {
                sugar_level -= kIntermediateRecipeSugar;
                spice_level -= kIntermediateRecipeSpice;
                const int intermediate_level = FLAMEGPU->getVariable<int>("intermediate_level") + 1;
                FLAMEGPU->setVariable<int>("sugar_level", sugar_level);
                FLAMEGPU->setVariable<int>("spice_level", spice_level);
                FLAMEGPU->setVariable<int>("intermediate_level", intermediate_level);
                production_stage = kProductionStageFinal;
                stage_progress = 0;
            }
        }
    } else if (production_stage == kProductionStageFinal) {
        const int period = EffectiveProductionPeriod(kRoundaboutFinalPeriod, capital_stock);
        ++stage_progress;
        if (stage_progress >= period) {
            int intermediate_level = FLAMEGPU->getVariable<int>("intermediate_level");
            if (intermediate_level < kFinalRecipeIntermediate) {
                production_stage = kProductionStageIdle;
                stage_progress = 0;
            } else {
                --intermediate_level;
                const int food_level = FLAMEGPU->getVariable<int>("food_level") + 1;
                FLAMEGPU->setVariable<int>("intermediate_level", intermediate_level);
                FLAMEGPU->setVariable<int>("food_level", food_level);
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
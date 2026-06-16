#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DEF(MetaboliseAndGrowback, flamegpu::MessageNone, flamegpu::MessageNone) {
    int sugar_level = FLAMEGPU->getVariable<int>("sugar_level");
    int spice_level = FLAMEGPU->getVariable<int>("spice_level");
    int env_sugar_level = FLAMEGPU->getVariable<int>("env_sugar_level");
    int env_spice_level = FLAMEGPU->getVariable<int>("env_spice_level");
    int env_max_sugar_level = FLAMEGPU->getVariable<int>("env_max_sugar_level");
    int env_max_spice_level = FLAMEGPU->getVariable<int>("env_max_spice_level");
    int status = FLAMEGPU->getVariable<int>("status");

    if (status == kAgentStatusOccupied || status == kAgentStatusMovementUnresolved) {
        if (env_sugar_level > 0) {
            sugar_level += env_sugar_level;
            env_sugar_level = -1;
        }
        if (env_spice_level > 0) {
            spice_level += env_spice_level;
            env_spice_level = -1;
        }

        int metabolism = FLAMEGPU->getVariable<int>("metabolism");
        while (metabolism > 0) {
            if (sugar_level > 0) {
                --sugar_level;
                --metabolism;
            } else if (spice_level > 0) {
                --spice_level;
                --metabolism;
            } else {
                break;
            }
        }

        if (sugar_level <= 0 && spice_level <= 0) {
            status = kAgentStatusUnoccupied;
            FLAMEGPU->setVariable<int>("agent_id", -1);
            FLAMEGPU->setVariable<float>("money", 0.0f);
            env_sugar_level = 0;
            env_spice_level = 0;
            FLAMEGPU->setVariable<int>("metabolism", 0);
        }
    }

    if (status == kAgentStatusUnoccupied) {
        if (env_sugar_level >= 0) {
            env_sugar_level += kSugarGrowbackRate;
            if (env_sugar_level > env_max_sugar_level) env_sugar_level = env_max_sugar_level;
        }
        if (env_spice_level >= 0) {
            env_spice_level += kSpiceGrowbackRate;
            if (env_spice_level > env_max_spice_level) env_spice_level = env_max_spice_level;
        }
    }

    if (status == kAgentStatusOccupied) {
        status = kAgentStatusMovementUnresolved;
    }

    FLAMEGPU->setVariable<int>("sugar_level", sugar_level);
    FLAMEGPU->setVariable<int>("spice_level", spice_level);
    FLAMEGPU->setVariable<int>("env_sugar_level", env_sugar_level);
    FLAMEGPU->setVariable<int>("env_spice_level", env_spice_level);
    FLAMEGPU->setVariable<int>("status", status);
    return flamegpu::ALIVE;
}

}  // namespace austrian_abm
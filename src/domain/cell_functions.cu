#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "data/goods_catalog.cuh"
#include "domain/inventory.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DEF(MetaboliseAndGrowback, flamegpu::MessageNone, flamegpu::MessageNone) {
    int env_sugar_level = FLAMEGPU->getVariable<int>("env_sugar_level");
    int env_spice_level = FLAMEGPU->getVariable<int>("env_spice_level");
    int env_iron_level = FLAMEGPU->getVariable<int>("env_iron_level");
    int env_coal_level = FLAMEGPU->getVariable<int>("env_coal_level");
    int env_max_sugar_level = FLAMEGPU->getVariable<int>("env_max_sugar_level");
    int env_max_spice_level = FLAMEGPU->getVariable<int>("env_max_spice_level");
    int env_max_iron_level = FLAMEGPU->getVariable<int>("env_max_iron_level");
    int env_max_coal_level = FLAMEGPU->getVariable<int>("env_max_coal_level");
    int status = FLAMEGPU->getVariable<int>("status");

    if (status == kAgentStatusOccupied || status == kAgentStatusMovementUnresolved) {
        if (env_sugar_level > 0) {
            InventoryAdd(FLAMEGPU, kGoodGrain, env_sugar_level);
            env_sugar_level = -1;
        }
        if (env_spice_level > 0) {
            InventoryAdd(FLAMEGPU, kGoodFruit, env_spice_level);
            env_spice_level = -1;
        }
        if (env_iron_level > 0) {
            InventoryAdd(FLAMEGPU, kGoodIron, env_iron_level);
            env_iron_level = -1;
        }
        if (env_coal_level > 0) {
            InventoryAdd(FLAMEGPU, kGoodCoal, env_coal_level);
            env_coal_level = -1;
        }

        int metabolism = FLAMEGPU->getVariable<int>("metabolism");
        while (metabolism > 0) {
            if (InventoryGet(FLAMEGPU, kGoodFood) > 0) {
                InventoryAdd(FLAMEGPU, kGoodFood, -1);
                metabolism -= kFoodMetabolismValue;
            } else if (InventoryGet(FLAMEGPU, kGoodGrain) > 0) {
                InventoryAdd(FLAMEGPU, kGoodGrain, -1);
                --metabolism;
            } else if (InventoryGet(FLAMEGPU, kGoodFruit) > 0) {
                InventoryAdd(FLAMEGPU, kGoodFruit, -1);
                --metabolism;
            } else {
                break;
            }
        }
        if (metabolism < 0) metabolism = 0;

        const bool destitute =
            InventoryGet(FLAMEGPU, kGoodGrain) <= 0
            && InventoryGet(FLAMEGPU, kGoodFruit) <= 0
            && InventoryGet(FLAMEGPU, kGoodFood) <= 0;
        if (destitute) {
            status = kAgentStatusUnoccupied;
            FLAMEGPU->setVariable<int>("agent_id", -1);
            FLAMEGPU->setVariable<float>("money", 0.0f);
            env_sugar_level = 0;
            env_spice_level = 0;
            env_iron_level = 0;
            env_coal_level = 0;
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
        if (env_iron_level >= 0) {
            env_iron_level += kIronGrowbackRate;
            if (env_iron_level > env_max_iron_level) env_iron_level = env_max_iron_level;
        }
        if (env_coal_level >= 0) {
            env_coal_level += kCoalGrowbackRate;
            if (env_coal_level > env_max_coal_level) env_coal_level = env_max_coal_level;
        }
    }

    if (status == kAgentStatusOccupied) {
        status = kAgentStatusMovementUnresolved;
    }

    FLAMEGPU->setVariable<int>("env_sugar_level", env_sugar_level);
    FLAMEGPU->setVariable<int>("env_spice_level", env_spice_level);
    FLAMEGPU->setVariable<int>("env_iron_level", env_iron_level);
    FLAMEGPU->setVariable<int>("env_coal_level", env_coal_level);
    FLAMEGPU->setVariable<int>("status", status);
    return flamegpu::ALIVE;
}

}  // namespace austrian_abm
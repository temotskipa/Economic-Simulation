#include "flamegpu/flamegpu.h"

#include "data/catalog_env.cuh"
#include "data/constants.cuh"
#include "data/goods_catalog.cuh"
#include "data/region.cuh"
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
            } else if (InventoryGet(FLAMEGPU, kGoodMeat) > 0) {
                InventoryAdd(FLAMEGPU, kGoodMeat, -1);
                metabolism -= kMeatMetabolismValue;
            } else if (InventoryGet(FLAMEGPU, kGoodFish) > 0) {
                InventoryAdd(FLAMEGPU, kGoodFish, -1);
                metabolism -= kFishMetabolismValue;
            } else if (InventoryGet(FLAMEGPU, kSvcHealthcare) > 0) {
                InventoryAdd(FLAMEGPU, kSvcHealthcare, -1);
                metabolism -= kHealthcareMetabolismValue;
            } else if (InventoryGet(FLAMEGPU, kGoodLiquor) > 0) {
                InventoryAdd(FLAMEGPU, kGoodLiquor, -1);
                metabolism -= kLiquorMetabolismValue;
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

        const unsigned int catalog_count = CatalogGoodCount(FLAMEGPU);
        for (unsigned int good = 0u; good < catalog_count; ++good) {
            if (!CatalogIsService(FLAMEGPU, static_cast<int>(good))) continue;
            const int decay = CatalogGoodDecay(FLAMEGPU, static_cast<int>(good));
            if (decay <= 0) continue;
            const int held = InventoryGet(FLAMEGPU, static_cast<int>(good));
            if (held <= 0) continue;
            const int remaining = held - decay;
            InventorySet(FLAMEGPU, static_cast<int>(good), remaining > 0 ? remaining : 0);
        }

        const bool destitute =
            InventoryGet(FLAMEGPU, kGoodGrain) <= 0
            && InventoryGet(FLAMEGPU, kGoodFruit) <= 0
            && InventoryGet(FLAMEGPU, kGoodFood) <= 0
            && InventoryGet(FLAMEGPU, kGoodMeat) <= 0
            && InventoryGet(FLAMEGPU, kGoodFish) <= 0;
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
        const unsigned int cell_x = FLAMEGPU->getVariable<unsigned int, 2>("pos", 0);
        const unsigned int cell_y = FLAMEGPU->getVariable<unsigned int, 2>("pos", 1);
        const float productivity = RegionProductivityAt(FLAMEGPU, cell_x, cell_y);
        int grow_delta = static_cast<int>(productivity + 0.5f);
        if (grow_delta < 1) grow_delta = 1;
        if (env_sugar_level >= 0) {
            env_sugar_level += grow_delta;
            if (env_sugar_level > env_max_sugar_level) env_sugar_level = env_max_sugar_level;
        }
        if (env_spice_level >= 0) {
            env_spice_level += grow_delta;
            if (env_spice_level > env_max_spice_level) env_spice_level = env_max_spice_level;
        }
        if (env_iron_level >= 0) {
            env_iron_level += grow_delta;
            if (env_iron_level > env_max_iron_level) env_iron_level = env_max_iron_level;
        }
        if (env_coal_level >= 0) {
            env_coal_level += grow_delta;
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
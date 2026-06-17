#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DEF(OutputCellStatus, flamegpu::MessageNone, flamegpu::MessageArray2D) {
    const unsigned int agent_x = FLAMEGPU->getVariable<unsigned int, 2>("pos", 0);
    const unsigned int agent_y = FLAMEGPU->getVariable<unsigned int, 2>("pos", 1);
    FLAMEGPU->message_out.setVariable("location_id", FLAMEGPU->getID());
    FLAMEGPU->message_out.setVariable("status", FLAMEGPU->getVariable<int>("status"));
    FLAMEGPU->message_out.setVariable("env_sugar_level", FLAMEGPU->getVariable<int>("env_sugar_level"));
    FLAMEGPU->message_out.setVariable("env_spice_level", FLAMEGPU->getVariable<int>("env_spice_level"));
    FLAMEGPU->message_out.setIndex(agent_x, agent_y);
    return flamegpu::ALIVE;
}

FLAMEGPU_AGENT_FUNCTION_DEF(MovementRequest, flamegpu::MessageArray2D, flamegpu::MessageArray2D) {
    int best_sugar_level = -1;
    int best_spice_level = -1;
    float best_random = -1.0f;
    flamegpu::id_t best_location_id = flamegpu::ID_NOT_SET;

    int status = FLAMEGPU->getVariable<int>("status");
    const unsigned int agent_x = FLAMEGPU->getVariable<unsigned int, 2>("pos", 0);
    const unsigned int agent_y = FLAMEGPU->getVariable<unsigned int, 2>("pos", 1);

    if (status == kAgentStatusMovementUnresolved) {
        for (auto current_message : FLAMEGPU->message_in.wrap(agent_x, agent_y)) {
            if (current_message.getVariable<int>("status") == kAgentStatusUnoccupied) {
                const int message_sugar = current_message.getVariable<int>("env_sugar_level");
                const int message_spice = current_message.getVariable<int>("env_spice_level");
                const int combined = message_sugar + message_spice;
                const float message_priority = FLAMEGPU->random.uniform<float>();
                if (combined > best_sugar_level + best_spice_level ||
                    (combined == best_sugar_level + best_spice_level && message_priority > best_random)) {
                    best_sugar_level = message_sugar;
                    best_spice_level = message_spice;
                    best_random = message_priority;
                    best_location_id = current_message.getVariable<flamegpu::id_t>("location_id");
                }
            }
        }
        status = best_location_id != flamegpu::ID_NOT_SET ? kAgentStatusMovementRequested : kAgentStatusOccupied;
        FLAMEGPU->setVariable<int>("status", status);
    }

    FLAMEGPU->message_out.setVariable<int>("agent_id", FLAMEGPU->getVariable<int>("agent_id"));
    FLAMEGPU->message_out.setVariable<flamegpu::id_t>("location_id", best_location_id);
    FLAMEGPU->message_out.setVariable<int>("sugar_level", FLAMEGPU->getVariable<int>("sugar_level"));
    FLAMEGPU->message_out.setVariable<int>("spice_level", FLAMEGPU->getVariable<int>("spice_level"));
    FLAMEGPU->message_out.setVariable<int>("metabolism", FLAMEGPU->getVariable<int>("metabolism"));
    FLAMEGPU->message_out.setVariable<float>("money", FLAMEGPU->getVariable<float>("money"));
    FLAMEGPU->message_out.setVariable<int>("food_level", FLAMEGPU->getVariable<int>("food_level"));
    FLAMEGPU->message_out.setVariable<float>("production_skill", FLAMEGPU->getVariable<float>("production_skill"));
    FLAMEGPU->message_out.setVariable<int>("activity_mode", FLAMEGPU->getVariable<int>("activity_mode"));
    FLAMEGPU->message_out.setVariable<int>("capital_stock", FLAMEGPU->getVariable<int>("capital_stock"));
    FLAMEGPU->message_out.setVariable<int>("intermediate_level", FLAMEGPU->getVariable<int>("intermediate_level"));
    FLAMEGPU->message_out.setVariable<float>("time_preference", FLAMEGPU->getVariable<float>("time_preference"));
    FLAMEGPU->message_out.setVariable<int>("production_stage", FLAMEGPU->getVariable<int>("production_stage"));
    FLAMEGPU->message_out.setVariable<int>("stage_progress", FLAMEGPU->getVariable<int>("stage_progress"));
    FLAMEGPU->message_out.setVariable<int>("is_capital_owner", FLAMEGPU->getVariable<int>("is_capital_owner"));
    FLAMEGPU->message_out.setIndex(agent_x, agent_y);
    return flamegpu::ALIVE;
}

FLAMEGPU_AGENT_FUNCTION_DEF(MovementResponse, flamegpu::MessageArray2D, flamegpu::MessageArray2D) {
    int best_request_id = -1;
    float best_request_priority = -1.0f;
    int best_request_sugar_level = 0;
    int best_request_spice_level = 0;
    int best_request_metabolism = 0;
    float best_request_money = 0.0f;
    int best_request_food_level = 0;
    float best_request_production_skill = 0.0f;
    int best_request_activity_mode = kActivityHarvest;
    int best_request_capital_stock = 0;
    int best_request_intermediate_level = 0;
    float best_request_time_preference = kMaxTimePreference;
    int best_request_production_stage = kProductionStageIdle;
    int best_request_stage_progress = 0;
    int best_request_is_capital_owner = 0;

    int status = FLAMEGPU->getVariable<int>("status");
    const flamegpu::id_t location_id = FLAMEGPU->getID();
    const unsigned int agent_x = FLAMEGPU->getVariable<unsigned int, 2>("pos", 0);
    const unsigned int agent_y = FLAMEGPU->getVariable<unsigned int, 2>("pos", 1);

    for (auto current_message : FLAMEGPU->message_in.wrap(agent_x, agent_y)) {
        if (status == kAgentStatusUnoccupied &&
            current_message.getVariable<flamegpu::id_t>("location_id") == location_id) {
            const float message_priority = FLAMEGPU->random.uniform<float>();
            if (message_priority > best_request_priority) {
                best_request_id = current_message.getVariable<int>("agent_id");
                best_request_priority = message_priority;
                best_request_sugar_level = current_message.getVariable<int>("sugar_level");
                best_request_spice_level = current_message.getVariable<int>("spice_level");
                best_request_metabolism = current_message.getVariable<int>("metabolism");
                best_request_money = current_message.getVariable<float>("money");
                best_request_food_level = current_message.getVariable<int>("food_level");
                best_request_production_skill = current_message.getVariable<float>("production_skill");
                best_request_activity_mode = current_message.getVariable<int>("activity_mode");
                best_request_capital_stock = current_message.getVariable<int>("capital_stock");
                best_request_intermediate_level = current_message.getVariable<int>("intermediate_level");
                best_request_time_preference = current_message.getVariable<float>("time_preference");
                best_request_production_stage = current_message.getVariable<int>("production_stage");
                best_request_stage_progress = current_message.getVariable<int>("stage_progress");
                best_request_is_capital_owner = current_message.getVariable<int>("is_capital_owner");
            }
        }
    }

    if (status == kAgentStatusUnoccupied && best_request_id >= 0) {
        FLAMEGPU->setVariable<int>("status", kAgentStatusOccupied);
        best_request_sugar_level += FLAMEGPU->getVariable<int>("env_sugar_level");
        best_request_spice_level += FLAMEGPU->getVariable<int>("env_spice_level");
        FLAMEGPU->setVariable<int>("agent_id", best_request_id);
        FLAMEGPU->setVariable<int>("sugar_level", best_request_sugar_level);
        FLAMEGPU->setVariable<int>("spice_level", best_request_spice_level);
        FLAMEGPU->setVariable<int>("metabolism", best_request_metabolism);
        FLAMEGPU->setVariable<float>("money", best_request_money);
        FLAMEGPU->setVariable<int>("food_level", best_request_food_level);
        FLAMEGPU->setVariable<float>("production_skill", best_request_production_skill);
        FLAMEGPU->setVariable<int>("activity_mode", best_request_activity_mode);
        FLAMEGPU->setVariable<int>("capital_stock", best_request_capital_stock);
        FLAMEGPU->setVariable<int>("intermediate_level", best_request_intermediate_level);
        FLAMEGPU->setVariable<float>("time_preference", best_request_time_preference);
        FLAMEGPU->setVariable<int>("production_stage", best_request_production_stage);
        FLAMEGPU->setVariable<int>("stage_progress", best_request_stage_progress);
        FLAMEGPU->setVariable<int>("is_capital_owner", best_request_is_capital_owner);
        FLAMEGPU->setVariable<int>("env_sugar_level", -1);
        FLAMEGPU->setVariable<int>("env_spice_level", -1);
    }

    FLAMEGPU->message_out.setVariable<int>("agent_id", best_request_id);
    FLAMEGPU->message_out.setIndex(agent_x, agent_y);
    return flamegpu::ALIVE;
}

FLAMEGPU_AGENT_FUNCTION_DEF(MovementTransaction, flamegpu::MessageArray2D, flamegpu::MessageNone) {
    int status = FLAMEGPU->getVariable<int>("status");
    const int agent_id = FLAMEGPU->getVariable<int>("agent_id");
    const unsigned int agent_x = FLAMEGPU->getVariable<unsigned int, 2>("pos", 0);
    const unsigned int agent_y = FLAMEGPU->getVariable<unsigned int, 2>("pos", 1);

    for (auto current_message : FLAMEGPU->message_in.wrap(agent_x, agent_y)) {
        if (status == kAgentStatusMovementRequested &&
            current_message.getVariable<int>("agent_id") == agent_id) {
            status = kAgentStatusUnoccupied;
            FLAMEGPU->setVariable<int>("agent_id", -1);
            FLAMEGPU->setVariable<int>("sugar_level", 0);
            FLAMEGPU->setVariable<int>("spice_level", 0);
            FLAMEGPU->setVariable<float>("money", 0.0f);
            FLAMEGPU->setVariable<int>("metabolism", 0);
            FLAMEGPU->setVariable<int>("food_level", 0);
            FLAMEGPU->setVariable<int>("activity_mode", kActivityHarvest);
            FLAMEGPU->setVariable<int>("step_production", 0);
            FLAMEGPU->setVariable<int>("capital_stock", 0);
            FLAMEGPU->setVariable<int>("intermediate_level", 0);
            FLAMEGPU->setVariable<float>("time_preference", kMaxTimePreference);
            FLAMEGPU->setVariable<int>("production_stage", kProductionStageIdle);
            FLAMEGPU->setVariable<int>("stage_progress", 0);
            FLAMEGPU->setVariable<int>("is_capital_owner", 0);
            FLAMEGPU->setVariable<int>("step_investment", 0);
            FLAMEGPU->setVariable<int>("env_sugar_level", 0);
            FLAMEGPU->setVariable<int>("env_spice_level", 0);
        }
    }

    if (status == kAgentStatusMovementRequested) {
        status = kAgentStatusMovementUnresolved;
    }
    FLAMEGPU->setVariable<int>("status", status);
    return flamegpu::ALIVE;
}

FLAMEGPU_EXIT_CONDITION(MovementExitCondition) {
    static unsigned int iterations = 0;
    ++iterations;
    if (iterations < 9u &&
        FLAMEGPU->agent("cell").count("status", kAgentStatusMovementUnresolved)) {
        return flamegpu::CONTINUE;
    }
    iterations = 0u;
    return flamegpu::EXIT;
}

}  // namespace austrian_abm
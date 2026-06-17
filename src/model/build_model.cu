#include "model/build_model.h"

#include "data/constants.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

namespace {

flamegpu::AgentDescription MakeCoreCell(flamegpu::ModelDescription& model) {
    flamegpu::AgentDescription cell = model.newAgent("cell");
    cell.newVariable<unsigned int, 2>("pos");
    cell.newVariable<int>("agent_id");
    cell.newVariable<int>("status");
    cell.newVariable<int>("sugar_level");
    cell.newVariable<int>("spice_level");
    cell.newVariable<int>("metabolism");
    cell.newVariable<float>("money");
    cell.newVariable<int>("env_sugar_level");
    cell.newVariable<int>("env_spice_level");
    cell.newVariable<int>("env_max_sugar_level");
    cell.newVariable<int>("env_max_spice_level");
    cell.newVariable<float>("sugar_bid");
    cell.newVariable<float>("sugar_ask");
    cell.newVariable<float>("spice_bid");
    cell.newVariable<float>("spice_ask");
    cell.newVariable<int>("food_level");
    cell.newVariable<float>("production_skill");
    cell.newVariable<int>("activity_mode");
    cell.newVariable<int>("step_production");
    cell.newVariable<int>("capital_stock");
    cell.newVariable<int>("intermediate_level");
    cell.newVariable<float>("time_preference");
    cell.newVariable<int>("production_stage");
    cell.newVariable<int>("stage_progress");
    cell.newVariable<int>("is_capital_owner");
    cell.newVariable<int>("step_investment");
    return cell;
}

}  // namespace

void BuildModel(flamegpu::ModelDescription& model, const SimulationConfig& config) {
    auto env = model.Environment();
    env.newProperty<unsigned int>("GRID_WIDTH", config.grid_width);
    env.newProperty<unsigned int>("GRID_HEIGHT", config.grid_height);
    env.newProperty<float>("OCCUPANCY", config.occupancy);
    env.newProperty<float>("INITIAL_MONEY", config.initial_money);
    env.newProperty<unsigned int>("RANDOM_SEED", config.seed);
    env.newProperty<unsigned int>("GOOD_STAGES", config.good_stages);
    env.newProperty<unsigned int>("AGENT_COUNT", 0u);
    env.newProperty<unsigned int>("TRADES_COUNT", 0u);
    env.newProperty<float>("TRADE_VOLUME", 0.0f);
    env.newProperty<float>("AVG_TRADE_PRICE", 0.0f);
    env.newProperty<float>("LAST_SUGAR_PRICE", 1.0f);
    env.newProperty<float>("LAST_SPICE_PRICE", 1.0f);
    env.newProperty<unsigned int>("PRODUCTION_COUNT", 0u);
    env.newProperty<unsigned int>("PRODUCER_COUNT", 0u);
    env.newProperty<unsigned int>("INVESTMENT_COUNT", 0u);
    env.newProperty<unsigned int>("ROUNDABOUT_COUNT", 0u);
    env.newProperty<long long>("TOTAL_CAPITAL", 0);

    flamegpu::ModelDescription movement_model("movement_model");
    {
        {
            auto message = movement_model.newMessage<flamegpu::MessageArray2D>("cell_status");
            message.newVariable<flamegpu::id_t>("location_id");
            message.newVariable<int>("status");
            message.newVariable<int>("env_sugar_level");
            message.newVariable<int>("env_spice_level");
            message.setDimensions(config.grid_width, config.grid_height);
        }
        {
            auto message = movement_model.newMessage<flamegpu::MessageArray2D>("movement_request");
            message.newVariable<int>("agent_id");
            message.newVariable<flamegpu::id_t>("location_id");
            message.newVariable<int>("sugar_level");
            message.newVariable<int>("spice_level");
            message.newVariable<int>("metabolism");
            message.newVariable<float>("money");
            message.newVariable<int>("food_level");
            message.newVariable<float>("production_skill");
            message.newVariable<int>("activity_mode");
            message.newVariable<int>("capital_stock");
            message.newVariable<int>("intermediate_level");
            message.newVariable<float>("time_preference");
            message.newVariable<int>("production_stage");
            message.newVariable<int>("stage_progress");
            message.newVariable<int>("is_capital_owner");
            message.setDimensions(config.grid_width, config.grid_height);
        }
        {
            auto message = movement_model.newMessage<flamegpu::MessageArray2D>("movement_response");
            message.newVariable<int>("agent_id");
            message.setDimensions(config.grid_width, config.grid_height);
        }

        flamegpu::AgentDescription cell = MakeCoreCell(movement_model);
        auto fn_output = cell.newFunction("OutputCellStatus", OutputCellStatus);
        fn_output.setMessageOutput("cell_status");
        auto fn_request = cell.newFunction("MovementRequest", MovementRequest);
        fn_request.setMessageInput("cell_status");
        fn_request.setMessageOutput("movement_request");
        auto fn_response = cell.newFunction("MovementResponse", MovementResponse);
        fn_response.setMessageInput("movement_request");
        fn_response.setMessageOutput("movement_response");
        auto fn_transaction = cell.newFunction("MovementTransaction", MovementTransaction);
        fn_transaction.setMessageInput("movement_response");

        movement_model.newLayer().addAgentFunction(fn_output);
        movement_model.newLayer().addAgentFunction(fn_request);
        movement_model.newLayer().addAgentFunction(fn_response);
        movement_model.newLayer().addAgentFunction(fn_transaction);
        movement_model.addExitCondition(MovementExitCondition);
    }

    {
        auto message = model.newMessage<flamegpu::MessageBruteForce>("trade_offer");
        message.newVariable<int>("agent_id");
        message.newVariable<int>("good");
        message.newVariable<int>("side");
        message.newVariable<float>("price");
        message.newVariable<int>("quantity");
    }

    flamegpu::AgentDescription cell = MakeCoreCell(model);
    cell.newFunction("MetaboliseAndGrowback", MetaboliseAndGrowback);
    cell.newFunction("ChooseProductionActivity", ChooseProductionActivity);
    cell.newFunction("InvestCapital", InvestCapital);
    cell.newFunction("AdvanceRoundaboutProduction", AdvanceRoundaboutProduction);
    cell.newFunction("ProduceFood", ProduceFood);
    auto fn_trade = cell.newFunction("OutputTradeOffers", OutputTradeOffers);
    fn_trade.setMessageOutput("trade_offer");

    flamegpu::SubModelDescription movement_sub =
        model.newSubModel("movement_conflict_resolution", movement_model);
    movement_sub.bindAgent("cell", "cell", true, true);

    model.newLayer("L1_MetaboliseAndGrowback").addAgentFunction(cell.getFunction("MetaboliseAndGrowback"));
    model.newLayer("L2_Movement").addSubModel(movement_sub);
    model.newLayer("L3_ChooseProductionActivity").addAgentFunction(cell.getFunction("ChooseProductionActivity"));
    model.newLayer("L4_InvestCapital").addAgentFunction(cell.getFunction("InvestCapital"));
    model.newLayer("L5_AdvanceRoundaboutProduction").addAgentFunction(cell.getFunction("AdvanceRoundaboutProduction"));
    model.newLayer("L6_ProduceFood").addAgentFunction(cell.getFunction("ProduceFood"));
    model.newLayer("L7_OutputTradeOffers").addAgentFunction(fn_trade);

    model.addStepFunction(MatchTrades);
    model.addStepFunction(LogMarketStep);
    model.addInitFunction(SeedGrid);
}

}  // namespace austrian_abm
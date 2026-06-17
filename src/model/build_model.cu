#include "model/build_model.h"

#include "data/constants.cuh"
#include "data/goods_catalog.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

namespace {

flamegpu::AgentDescription MakeCoreCell(flamegpu::ModelDescription& model) {
    flamegpu::AgentDescription cell = model.newAgent("cell");
    cell.newVariable<unsigned int, 2>("pos");
    cell.newVariable<int>("agent_id");
    cell.newVariable<int>("status");
    cell.newVariable<int, kMaxGoods>("inventory");
    cell.newVariable<int>("metabolism");
    cell.newVariable<float>("money");
    cell.newVariable<int>("env_sugar_level");
    cell.newVariable<int>("env_spice_level");
    cell.newVariable<int>("env_iron_level");
    cell.newVariable<int>("env_coal_level");
    cell.newVariable<int>("env_max_sugar_level");
    cell.newVariable<int>("env_max_spice_level");
    cell.newVariable<int>("env_max_iron_level");
    cell.newVariable<int>("env_max_coal_level");
    cell.newVariable<float, kMaxGoods>("bid_price");
    cell.newVariable<float, kMaxGoods>("ask_price");
    cell.newVariable<float>("production_skill");
    cell.newVariable<int>("activity_mode");
    cell.newVariable<int>("step_production");
    cell.newVariable<int>("capital_stock");
    cell.newVariable<float>("time_preference");
    cell.newVariable<int>("production_stage");
    cell.newVariable<int>("stage_progress");
    cell.newVariable<int>("is_capital_owner");
    cell.newVariable<int>("step_investment");
    cell.newVariable<float>("loan_balance");
    cell.newVariable<float>("deposit_balance");
    cell.newVariable<float>("loan_rate");
    cell.newVariable<int>("step_loan");
    cell.newVariable<int>("arbitrage_signals");
    return cell;
}

flamegpu::AgentDescription MakeBank(flamegpu::ModelDescription& model) {
    flamegpu::AgentDescription bank = model.newAgent("bank");
    bank.newVariable<unsigned int, 2>("pos");
    bank.newVariable<int>("bank_id");
    bank.newVariable<float>("reserves");
    bank.newVariable<float>("deposits");
    bank.newVariable<float>("loans_outstanding");
    return bank;
}

}  // namespace

void BuildModel(
    flamegpu::ModelDescription& model,
    const SimulationConfig& config,
    const SimulationCatalog& catalog) {
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
    UploadCatalogToEnvironment(env, catalog);
    env.newProperty<float>("TRADE_RADIUS", config.trade_radius);
    env.newProperty<float, kMaxRegions>("REGION_PRODUCTIVITY", config.region_productivity);
    env.newProperty<unsigned int>("PRODUCTION_COUNT", 0u);
    env.newProperty<unsigned int>("PRODUCER_COUNT", 0u);
    env.newProperty<unsigned int>("INVESTMENT_COUNT", 0u);
    env.newProperty<unsigned int>("ROUNDABOUT_COUNT", 0u);
    env.newProperty<long long>("TOTAL_CAPITAL", 0);
    env.newProperty<float>("NATURAL_RATE", config.natural_rate);
    env.newProperty<float>("POLICY_RATE", config.policy_rate);
    env.newProperty<unsigned int>("RATE_SHOCK_STEP", config.rate_shock_step);
    env.newProperty<float>("EFFECTIVE_RATE", config.policy_rate);
    env.newProperty<unsigned int>("RATE_SUPPRESSED", 1u);
    env.newProperty<unsigned int>("CREDIT_CREATED", 0u);
    env.newProperty<float>("TOTAL_LOANS", 0.0f);
    env.newProperty<float>("TOTAL_DEPOSITS", 0.0f);
    env.newProperty<unsigned int>("MALINVESTMENT_COUNT", 0u);

    flamegpu::ModelDescription movement_model("movement_model");
    {
        {
            auto message = movement_model.newMessage<flamegpu::MessageArray2D>("cell_status");
            message.newVariable<flamegpu::id_t>("location_id");
            message.newVariable<int>("status");
            message.newVariable<int>("env_sugar_level");
            message.newVariable<int>("env_spice_level");
            message.newVariable<int>("env_iron_level");
            message.newVariable<int>("env_coal_level");
            message.setDimensions(config.grid_width, config.grid_height);
        }
        {
            auto message = movement_model.newMessage<flamegpu::MessageArray2D>("movement_request");
            message.newVariable<int>("agent_id");
            message.newVariable<flamegpu::id_t>("location_id");
            message.newVariable<int, kMaxGoods>("inventory");
            message.newVariable<int>("metabolism");
            message.newVariable<float>("money");
            message.newVariable<float>("production_skill");
            message.newVariable<int>("activity_mode");
            message.newVariable<int>("capital_stock");
            message.newVariable<float>("time_preference");
            message.newVariable<int>("production_stage");
            message.newVariable<int>("stage_progress");
            message.newVariable<int>("is_capital_owner");
            message.newVariable<float>("loan_balance");
            message.newVariable<float>("deposit_balance");
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
        auto message = model.newMessage<flamegpu::MessageSpatial2D>("trade_offer");
        message.newVariable<int>("agent_id");
        message.newVariable<int>("good");
        message.newVariable<int>("side");
        message.newVariable<float>("price");
        message.newVariable<int>("quantity");
        message.setMin(0.0f, 0.0f);
        message.setMax(
            static_cast<float>(config.grid_width),
            static_cast<float>(config.grid_height));
        message.setRadius(config.trade_radius);
    }

    MakeBank(model);

    flamegpu::AgentDescription cell = MakeCoreCell(model);
    cell.newFunction("MetaboliseAndGrowback", MetaboliseAndGrowback);
    cell.newFunction("ChooseProductionActivity", ChooseProductionActivity);
    cell.newFunction("InvestCapital", InvestCapital);
    cell.newFunction("AdvanceRoundaboutProduction", AdvanceRoundaboutProduction);
    cell.newFunction("ProduceFromRecipes", ProduceFromRecipes);
    auto fn_trade = cell.newFunction("OutputTradeOffers", OutputTradeOffers);
    fn_trade.setMessageOutput("trade_offer");
    auto fn_arbitrage = cell.newFunction("ScanSpatialArbitrage", ScanSpatialArbitrage);
    fn_arbitrage.setMessageInput("trade_offer");

    flamegpu::SubModelDescription movement_sub =
        model.newSubModel("movement_conflict_resolution", movement_model);
    movement_sub.bindAgent("cell", "cell", true, true);

    model.newLayer("L1_MetaboliseAndGrowback").addAgentFunction(cell.getFunction("MetaboliseAndGrowback"));
    model.newLayer("L2_Movement").addSubModel(movement_sub);
    model.newLayer("L2b_Banking").addHostFunction(ProcessBanking);
    model.newLayer("L3_ChooseProductionActivity").addAgentFunction(cell.getFunction("ChooseProductionActivity"));
    model.newLayer("L4_InvestCapital").addAgentFunction(cell.getFunction("InvestCapital"));
    model.newLayer("L5_AdvanceRoundaboutProduction").addAgentFunction(cell.getFunction("AdvanceRoundaboutProduction"));
    model.newLayer("L6_ProduceFromRecipes").addAgentFunction(cell.getFunction("ProduceFromRecipes"));
    model.newLayer("L7_OutputTradeOffers").addAgentFunction(fn_trade);
    model.newLayer("L7b_ScanSpatialArbitrage").addAgentFunction(fn_arbitrage);

    model.addStepFunction(MatchTrades);
    model.addStepFunction(LogMarketStep);
    model.addInitFunction(SeedGrid);
    model.addInitFunction(SeedBanks);
}

}  // namespace austrian_abm
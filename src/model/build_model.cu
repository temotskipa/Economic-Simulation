#include "model/build_model.h"

#include "data/constants.cuh"
#include "io/config.h"
#include "model/model_symbols.cuh"

namespace austrian_abm {

void BuildModel(flamegpu::ModelDescription& model) {
    auto env = model.Environment();

    env.newProperty<unsigned int>("CONSUMER_COUNT",
        ParseUnsignedEnv("AUSTRIAN_ABM_CONSUMERS", kDefaultConsumerCount));
    env.newProperty<unsigned int>("PRODUCER_COUNT",
        ParseUnsignedEnv("AUSTRIAN_ABM_PRODUCERS", kDefaultProducerCount));
    env.newProperty<unsigned int>("MARKET_STEPS",
        ParseUnsignedEnv("AUSTRIAN_ABM_MARKET_STEPS", kDefaultMarketSteps));
    env.newProperty<unsigned int>("RANDOM_SEED", ParseRandomSeedEnv());
    env.newProperty<unsigned int>("MARKET_STEP", 0u);
    env.newProperty<float>("CLEARING_PRICE",
        ParseFloatEnv("AUSTRIAN_ABM_INITIAL_PRICE", kDefaultClearingPrice));

    auto consumer = model.newAgent("consumer");
    consumer.newVariable<float>("cash");
    consumer.newVariable<float>("goods_held");
    consumer.newVariable<float>("time_preference");
    consumer.newVariable<float>("base_utility");
    consumer.newVariable<float>("reservation_price");
    consumer.newVariable<float>("desired_qty");
    consumer.newVariable<float>("last_trade_qty");
    consumer.newFunction("ConsumerPlanPurchase", ConsumerPlanPurchase);
    consumer.newFunction("ConsumerExecuteTrade", ConsumerExecuteTrade);

    auto producer = model.newAgent("producer");
    producer.newVariable<float>("capital");
    producer.newVariable<float>("productivity");
    producer.newVariable<float>("unit_cost");
    producer.newVariable<float>("alertness");
    producer.newVariable<float>("inventory");
    producer.newVariable<float>("ask_price");
    producer.newVariable<float>("last_output");
    producer.newFunction("ProducerProduce", ProducerProduce);
    producer.newFunction("ProducerSetPrice", ProducerSetPrice);

    model.newLayer("L1_ProducerProduce").addAgentFunction(producer.getFunction("ProducerProduce"));
    model.newLayer("L2_ProducerSetPrice").addAgentFunction(producer.getFunction("ProducerSetPrice"));
    model.newLayer("L3_ConsumerPlanPurchase").addAgentFunction(consumer.getFunction("ConsumerPlanPurchase"));
    model.newLayer("L4_ConsumerExecuteTrade").addAgentFunction(consumer.getFunction("ConsumerExecuteTrade"));

    model.addStepFunction(AdvanceMarket);

    model.addInitFunction(SeedConsumers);
    model.addInitFunction(SeedProducers);
}

}  // namespace austrian_abm
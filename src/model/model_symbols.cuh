#pragma once

#include "flamegpu/flamegpu.h"

namespace austrian_abm {

FLAMEGPU_AGENT_FUNCTION_DECL(ConsumerPlanPurchase, flamegpu::MessageNone, flamegpu::MessageNone);
FLAMEGPU_AGENT_FUNCTION_DECL(ConsumerExecuteTrade, flamegpu::MessageNone, flamegpu::MessageNone);
FLAMEGPU_AGENT_FUNCTION_DECL(ProducerProduce, flamegpu::MessageNone, flamegpu::MessageNone);
FLAMEGPU_AGENT_FUNCTION_DECL(ProducerSetPrice, flamegpu::MessageNone, flamegpu::MessageNone);

FLAMEGPU_HOST_FUNCTION_DECL(SeedConsumers);
FLAMEGPU_HOST_FUNCTION_DECL(SeedProducers);
FLAMEGPU_HOST_FUNCTION_DECL(AdvanceMarket);

}  // namespace austrian_abm
#pragma once

namespace austrian_abm {

constexpr char kModelName[] = "Austrian ABM Simulation";
constexpr unsigned int kDefaultRandomSeed = 42u;
constexpr unsigned int kDefaultConsumerCount = 100000u;
constexpr unsigned int kDefaultProducerCount = 500u;
constexpr unsigned int kDefaultMarketSteps = 12u;
constexpr float kDefaultClearingPrice = 1.0f;
constexpr float kMinPrice = 0.01f;
constexpr float kMaxPrice = 100.0f;
constexpr float kPi = 3.14159265358979323846f;

}  // namespace austrian_abm
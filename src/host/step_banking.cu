#include <cstdio>

#include "flamegpu/flamegpu.h"

#include "data/constants.cuh"
#include "domain/credit_functions.cuh"
#include "model/model_symbols.cuh"

namespace austrian_abm {

FLAMEGPU_HOST_FUNCTION(ProcessBanking) {
    const unsigned int step = FLAMEGPU->getStepCounter();
    const float natural_rate = FLAMEGPU->environment.getProperty<float>("NATURAL_RATE");
    const float policy_rate = FLAMEGPU->environment.getProperty<float>("POLICY_RATE");
    const unsigned int shock_step = FLAMEGPU->environment.getProperty<unsigned int>("RATE_SHOCK_STEP");

    const float effective_rate = step < shock_step ? policy_rate : natural_rate;
    const unsigned int rate_suppressed = step < shock_step ? 1u : 0u;
    FLAMEGPU->environment.setProperty<float>("EFFECTIVE_RATE", effective_rate);
    FLAMEGPU->environment.setProperty<unsigned int>("RATE_SUPPRESSED", rate_suppressed);

    if (step == shock_step) {
        std::printf("RATE SHOCK at step %u: effective_rate %.4f -> %.4f\n",
            shock_step, policy_rate, natural_rate);
    }

    flamegpu::DeviceAgentVector cells = FLAMEGPU->agent("cell").getPopulationData();
    flamegpu::DeviceAgentVector banks = FLAMEGPU->agent("bank").getPopulationData();

    double total_deposits = 0.0;
    for (unsigned int i = 0; i < cells.size(); ++i) {
        if (cells[i].getVariable<int>("status") != kAgentStatusOccupied) continue;
        float money = cells[i].getVariable<float>("money");
        if (money <= kDepositThreshold) continue;
        const float deposit_amount = money * kDepositFraction;
        money -= deposit_amount;
        const float deposit_balance = cells[i].getVariable<float>("deposit_balance") + deposit_amount;
        cells[i].setVariable<float>("money", money);
        cells[i].setVariable<float>("deposit_balance", deposit_balance);
        total_deposits += deposit_amount;
    }

    unsigned int credit_created = 0u;
    double total_loans = 0.0;
    unsigned int bank_index = 0u;
    const bool credit_expansion = effective_rate < natural_rate;

    if (credit_expansion) {
        for (unsigned int i = 0; i < cells.size(); ++i) {
            if (cells[i].getVariable<int>("status") != kAgentStatusOccupied) continue;
            const float production_skill = cells[i].getVariable<float>("production_skill");
            const int grain_level = cells[i].getVariable<int, kGoodCount>("inventory", kGoodGrain);
            const int fruit_level = cells[i].getVariable<int, kGoodCount>("inventory", kGoodFruit);
            const float loan_balance = cells[i].getVariable<float>("loan_balance");
            const int min_grain = FLAMEGPU->environment.getProperty<int>("CREDIT_MIN_GRAIN");
            const int min_fruit = FLAMEGPU->environment.getProperty<int>("CREDIT_MIN_FRUIT");
            if (!IsEntrepreneurEligibleForCredit(
                    production_skill, grain_level, fruit_level, loan_balance, min_grain, min_fruit)) {
                continue;
            }

            if (banks.size() == 0u) break;
            const unsigned int bank_idx = bank_index % banks.size();
            bank_index++;

            const float reserves = banks[bank_idx].getVariable<float>("reserves");
            const float loans_outstanding = banks[bank_idx].getVariable<float>("loans_outstanding");
            const float lending_capacity = reserves * kReserveLendingMultiplier - loans_outstanding;
            if (lending_capacity < kDefaultLoanSize) continue;

            const float loan_amount = kDefaultLoanSize;
            float money = cells[i].getVariable<float>("money");
            money += loan_amount;
            cells[i].setVariable<float>("money", money);
            cells[i].setVariable<float>("loan_balance", loan_balance + loan_amount);
            cells[i].setVariable<float>("loan_rate", effective_rate);
            cells[i].setVariable<int>("step_loan", 1);
            banks[bank_idx].setVariable<float>("loans_outstanding", loans_outstanding + loan_amount);
            banks[bank_idx].setVariable<float>("deposits",
                banks[bank_idx].getVariable<float>("deposits") + loan_amount);

            ++credit_created;
            total_loans += loan_amount;
        }
    } else {
        for (unsigned int i = 0; i < cells.size(); ++i) {
            cells[i].setVariable<int>("step_loan", 0);
        }
    }

    FLAMEGPU->environment.setProperty<unsigned int>("CREDIT_CREATED", credit_created);
    FLAMEGPU->environment.setProperty<float>("TOTAL_LOANS", static_cast<float>(total_loans));
    FLAMEGPU->environment.setProperty<float>("TOTAL_DEPOSITS", static_cast<float>(total_deposits));

    if (credit_created > 0u) {
        std::printf("credit_created=%u effective_rate=%.4f total_loans=%.0f\n",
            credit_created, effective_rate, total_loans);
    }
}

}  // namespace austrian_abm
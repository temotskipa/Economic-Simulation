#include <cassert>
#include <cstdio>

#include "domain/marginal_utility.h"

int main() {
    using austrian_abm::detail::EntrepreneurAskPrice;
    using austrian_abm::detail::SubjectiveReservationPrice;

    const float reservation = SubjectiveReservationPrice(100.0f, 0.2f, 1.0f, 1.5f);
    assert(reservation > 0.01f);
    assert(reservation <= 100.0f);

    const float high_time_pref = SubjectiveReservationPrice(100.0f, 0.9f, 0.0f, 1.5f);
    const float low_time_pref = SubjectiveReservationPrice(100.0f, 0.1f, 0.0f, 1.5f);
    assert(low_time_pref >= high_time_pref);

    const float ask = EntrepreneurAskPrice(1.0f, 2.0f, 0.5f, 1.2f);
    assert(ask >= 1.0f);

    const float satiated = SubjectiveReservationPrice(50.0f, 0.5f, 20.0f, 2.0f);
    const float hungry = SubjectiveReservationPrice(50.0f, 0.5f, 0.0f, 2.0f);
    assert(hungry > satiated);

    std::printf("test_marginal_utility: all assertions passed\n");
    return 0;
}
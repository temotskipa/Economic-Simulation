#pragma once

#include "flamegpu/flamegpu.h"

namespace austrian_abm {

FLAMEGPU_HOST_DEVICE_FUNCTION float ClampFloat(const float v, const float lo, const float hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

}  // namespace austrian_abm
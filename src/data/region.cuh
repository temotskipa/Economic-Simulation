#pragma once

#include "data/constants.cuh"

namespace austrian_abm {

FLAMEGPU_HOST_DEVICE_FUNCTION inline int ComputeRegionId(
    const unsigned int x,
    const unsigned int y,
    const unsigned int grid_width,
    const unsigned int grid_height) {
    const unsigned int half_w = grid_width / 2u;
    const unsigned int half_h = grid_height / 2u;
    const int x_band = x < half_w ? 0 : 1;
    const int y_band = y < half_h ? 0 : 2;
    return x_band + y_band;
}

#define RegionProductivityAt(api, x, y) ( \
    (api)->environment.getProperty<float, kMaxRegions>( \
        "REGION_PRODUCTIVITY", \
        ComputeRegionId( \
            (x), (y), \
            (api)->environment.getProperty<unsigned int>("GRID_WIDTH"), \
            (api)->environment.getProperty<unsigned int>("GRID_HEIGHT"))))

}  // namespace austrian_abm
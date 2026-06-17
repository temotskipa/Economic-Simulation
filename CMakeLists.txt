# Minimum CMake version 3.25.2 for CUDA --std=c++20
cmake_minimum_required(VERSION 3.25.2...4.1.1 FATAL_ERROR)

set(FLAMEGPU_VERSION "master" CACHE STRING "FLAMEGPU/FLAMEGPU2 git branch, tag, or commit hash")

option(FLAMEGPU_VISUALISATION "Enable FLAMEGPU visualisation support" OFF)

if(NOT CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES 89 CACHE STRING "CUDA architectures (RTX 4070 Ti = sm_89)" FORCE)
endif()

include(${CMAKE_CURRENT_LIST_DIR}/cmake/flamegpu2.cmake)

include(${FLAMEGPU_ROOT}/cmake/CUDAArchitectures.cmake)
flamegpu_init_cuda_architectures(PROJECT austrian_abm)

project(austrian_abm CUDA CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

include(${FLAMEGPU_ROOT}/cmake/common.cmake)

SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin/${CMAKE_BUILD_TYPE}/)

SET(ALL_SRC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/model/build_model.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/cell_functions.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/movement_functions.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/trade_functions.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/production_functions.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/capital_functions.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/host/seed_grid.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/host/seed_banks.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/host/step_banking.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/host/step_match_trades.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/host/step_log.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/io/config.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/io/catalog_loader.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/io/report_html.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/data/constants.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/data/goods_catalog.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/data/catalog_env.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/data/region.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/inventory.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/io/catalog.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/trade_functions.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/production_functions.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/present_value.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/capital_functions.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/credit_functions.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/io/report_html.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/model/build_model.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/model/model_symbols.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/host/step_log.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/util/math.cuh
)

flamegpu_add_executable("${PROJECT_NAME}" "${ALL_SRC}" "${FLAMEGPU_ROOT}" "${PROJECT_BINARY_DIR}" OFF)

target_include_directories("${PROJECT_NAME}" PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_BINARY_DIR}/_deps/nlohmann_json-src/include")

set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY VS_STARTUP_PROJECT "${PROJECT_NAME}")
set_target_properties("${PROJECT_NAME}" PROPERTIES
    VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    VS_DEBUGGER_COMMAND_ARGUMENTS "--steps 12 --seed 42"
)
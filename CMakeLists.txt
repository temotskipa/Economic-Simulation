# Minimum CMake version 3.25.2 for CUDA --std=c++20
cmake_minimum_required(VERSION 3.25.2...4.1.1 FATAL_ERROR)

# FLAME GPU 2: always fetch latest upstream master on configure.
set(FLAMEGPU_VERSION "master" CACHE STRING "FLAMEGPU/FLAMEGPU2 git branch, tag, or commit hash")
# Fork override if upstream is unreachable: -DFLAMEGPU_REPOSITORY=https://github.com/temotskipa/FLAMEGPU2.git

# Manually specify the FLAMEGPU_VISUALISATION option to provide it prior to original configuration and allow the default to be overridden in the downstream project
option(FLAMEGPU_VISUALISATION "Enable FLAMEGPU visualisation support" OFF)

# Our core dependency is FLAMEGPU2 lib, first lets find it
include(${CMAKE_CURRENT_LIST_DIR}/cmake/flamegpu2.cmake)

# Handle CMAKE_CUDA_ARCHITECTURES gracefully, passing the project name for code-injection
include(${FLAMEGPU_ROOT}/cmake/CUDAArchitectures.cmake)
flamegpu_init_cuda_architectures(PROJECT austrian_abm_simulation)

# Name the project and set languages, this must be done after flamegpu_init_cuda_architectures
project(austrian_abm_simulation CUDA CXX)

# Enforce modern standard (C++20 — highest universally supported by CUDA 13.x)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# Include common rules from the FLAMEGPU/FLAMEGPU2 repositories CMake
include(${FLAMEGPU_ROOT}/cmake/common.cmake)

# Define output location of binary files
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin/${CMAKE_BUILD_TYPE}/)

# Manually list all of the files which require building or influence re-building (i.e. headers).
SET(ALL_SRC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/model/build_model.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/model/agents/consumer_functions.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/model/agents/producer_functions.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/model/init/seed_consumers.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/model/init/seed_producers.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/host/step_advance_market.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/io/config.cu
    ${CMAKE_CURRENT_SOURCE_DIR}/src/data/constants.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/marginal_utility.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/domain/marginal_utility.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/model/build_model.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/model/model_symbols.cuh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/util/math.cuh
)

# Add the executable and set required flags for the target
flamegpu_add_executable("${PROJECT_NAME}" "${ALL_SRC}" "${FLAMEGPU_ROOT}" "${PROJECT_BINARY_DIR}" OFF)

# Add src directory to include path
target_include_directories("${PROJECT_NAME}" PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

# Also set as (visual studio) startup project
set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY VS_STARTUP_PROJECT "${PROJECT_NAME}")

# Set the default (visual studio) debugger configuration
set_target_properties("${PROJECT_NAME}" PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" VS_DEBUGGER_COMMAND_ARGUMENTS "-s 1")

add_executable(test_marginal_utility
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_marginal_utility.cpp
)
target_include_directories(test_marginal_utility PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
target_compile_features(test_marginal_utility PRIVATE cxx_std_20)
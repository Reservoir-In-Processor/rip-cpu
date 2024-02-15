cmake_minimum_required(VERSION 3.14)
project(rip_test)

####################
# Verilator
####################

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

####################
# GoogleTest
####################

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_COLOR_DIAGNOSTICS ON)
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
)

# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

####################
# Test
####################

enable_testing()
add_executable(test_all
  test_inst.cpp
  test_decode.cpp
  test_alu.cpp
  test_riscv_tests.cpp
  test_dump.cpp
  main.cpp
)
target_link_libraries(
  test_all
  PRIVATE
  GTest::gtest_main
)

set_target_properties(test_all PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED ON
  COMPILE_FLAGS "-Wall -g -fsanitize=address,undefined"
  LINK_FLAGS "-fsanitize=address,undefined"
)

include(GoogleTest)
gtest_discover_tests(test_all)

# unit tests
verilate(test_all
  INCLUDE_DIRS "../src"
  SOURCES
  ../src/rip_const.sv
  ../src/rip_config.sv
  ../src/rip_type.sv
  ../src/rip_decode.sv
  PREFIX Vdecode
)

verilate(test_all
  INCLUDE_DIRS "../src"
  SOURCES
  ../src/rip_const.sv
  ../src/rip_config.sv
  ../src/rip_type.sv
  ../src/rip_alu.sv
  PREFIX Valu
)

# export waveform
verilate(test_all
  INCLUDE_DIRS "../src"
  SOURCES
    ../src/rip_const.sv
    ../src/rip_config.sv
    ../src/rip_type.sv
    ../src/rip_2r1w_bram.sv
    ../src/rip_branch_predictor.sv
    ../src/rip_alu.sv
    ../src/rip_regfile.sv
    ../src/rip_csr.sv
    ../src/stub/rip_mmu_stub.sv
    ../src/rip_memory_access.sv
    ../src/rip_decode.sv
    ../src/rip_core.sv
  TOP_MODULE rip_core
  PREFIX Vcore
  VERILATOR_ARGS
    --trace
    --trace-params
    --trace-structs
    --trace-underscore
)

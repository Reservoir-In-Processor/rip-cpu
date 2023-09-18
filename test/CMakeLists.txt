cmake_minimum_required(VERSION 3.14)
project(RISCoffee_test)

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
  test_core.cpp
  test_all.cpp
)
target_link_libraries(
  test_all
  PRIVATE
  GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(test_all)

# unit tests
verilate(test_all
  INCLUDE_DIRS "../src"
  SOURCES
  ../src/instructions.svh
  ../src/decode.sv
  PREFIX Vdecode
)

# export waveform
verilate(test_all
  INCLUDE_DIRS "../src"
  SOURCES
    ../src/instructions.svh
    ../src/alu.sv
    ../src/regfile.sv
    ../src/csr.sv
    ../src/pc.sv
    ../src/ram.sv
    ../src/decode.sv
    ../src/core.sv
  TOP_MODULE riscoffee_core
  PREFIX Vcore
  VERILATOR_ARGS
    --trace
    --trace-params
    --trace-structs
    --trace-underscore
)

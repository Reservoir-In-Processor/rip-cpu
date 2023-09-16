cmake_minimum_required(VERSION 3.13)
project(RISCoffee_test)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

add_executable(sim test_core.cpp)

verilate(sim
  INCLUDE_DIRS
    "../src"
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
  PREFIX Vriscoffee_core
  VERILATOR_ARGS
    --trace
    --trace-params
    --trace-structs
    --trace-underscore
)

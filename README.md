# rip-cpu

[![Linter](https://github.com/Reservoir-In-Processor/rip-cpu/actions/workflows/linter.yaml/badge.svg)](https://github.com/Reservoir-In-Processor/rip-cpu/actions/workflows/linter.yaml)
[![Verilator Test](https://github.com/Reservoir-In-Processor/rip-cpu/actions/workflows/main.yaml/badge.svg)](https://github.com/Reservoir-In-Processor/rip-cpu/actions/workflows/main.yaml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This project implements a pipeline processor for the RV32IM instruction set architecture in SystemVerilog.

## Requirements

To use this project, you need to have the following tools installed:

- [Ninja](https://ninja-build.org/)
- [Verilator](https://www.veripool.org/verilator/) (version 5.004 or higher)

Make sure these tools are installed on your system before proceeding with the project.

## Usage

### Verilator Test

1. **Building and Verifying the Processor**
   
    To build the processor in Verilator and verify the project, follow these steps:

    ```bash
    cd test
    cmake -S . -B build -G Ninja
    ninja -C build
    ```

2. **Running the Verilated Simulation**
   
    Once the project is built, run the Verilated simulation using the following command:

    ```bash
    cd build
    ./test_all
    ```

3. **Simulation Output**
   
    The command will generate the following output:

    - Unit test results for each module
    - Results of integration tests using riscv-tests and waveform dumps (test/dump/*.vcd)
    - Register and waveform dumps for Dhrystone benchmarks (test/build/dump.txt, test/build/simx.vcd)

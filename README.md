# RISCoffee
Processor implemented in System Verilog based on RISC-V ISA

## Build Instructions

To build the project, follow these steps:

```bash
cd test
cmake -S . -B build -G Ninja
ninja -C build
```

Once the project is built, you can run the Verilated simulation using the following command:

```bash
build/sim
```

This command will execute the simulation, and as a result, a waveform file named `simx.vcd` will be generated.

#include <iostream>
#include <verilated.h>
#include "Vriscoffee_core.h"
#include <verilated_vcd_c.h>

int time_counter = 0;
int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // Instantiate DUT
    Vriscoffee_core* dut = new Vriscoffee_core();

    // Trace DUMP ON
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;

    dut->trace(tfp, 100);  // Trace 100 levels of hierarchy
    tfp->open("simx.vcd");

    // Format
    dut->RST_N = 0;
    dut->CLK = 0;

    int cycle = 0;
    while (time_counter < 50000) {
        if (time_counter == 100) {
            dut->RST_N = 1;
        }

        if ((time_counter % 5) == 0) {
            dut->CLK = !dut->CLK;  // Toggle clock
        }
        if ((time_counter % 10) == 0) {
            // Cycle Count
            cycle++;
        }

        // Evaluate DUT
        dut->eval();
        
        tfp->dump(time_counter);

        time_counter++;
    }

    dut->final();
}
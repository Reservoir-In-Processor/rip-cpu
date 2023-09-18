#include <fstream>

#include <verilated.h>
#include "Vcore.h"
#include <verilated_vcd_c.h>

#include <gtest/gtest.h>

namespace {

constexpr int TIME_MAX = 50000;
const char* WAVEFORM_FILE = "simx.vcd";
TEST(TestCore, ExportWaveform) {
    // Instantiate DUT
    Vcore* dut = new Vcore();

    // Trace DUMP ON
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;

    dut->trace(tfp, 100);  // Trace 100 levels of hierarchy
    tfp->open(WAVEFORM_FILE);

    // Format
    dut->RST_N = 0;
    dut->CLK = 0;

    for (int time_counter = 0; time_counter < TIME_MAX; time_counter++) {
        if (time_counter == 100) {
            dut->RST_N = 1;
        }

        if ((time_counter % 5) == 0) {
            dut->CLK = !dut->CLK;  // Toggle clock
        }

        // Evaluate DUT
        dut->eval();        
        tfp->dump(time_counter);
    }

    dut->final();
    tfp->close();
    delete dut;
    delete tfp;

    // check if waveform file is created
    std::ifstream ifs(WAVEFORM_FILE);
    EXPECT_TRUE(ifs.is_open());
    ifs.close();
}

}

#include <filesystem>
#include <fstream>

#include <verilated.h>
#include "Vcore.h"
#include <verilated_vcd_c.h>

#include <gtest/gtest.h>

namespace {

constexpr int TIME_MAX = 100000;    // for fib(10) simulation
const char* WAVEFORM_FILE = "simx.vcd";
TEST(TestCore, ExportWaveform) {
    // Instantiate DUT
    std::string testcase_filename = "../../hex/fib.hex";
    std::string tmp_filename = "../../hex/testcase.hex";
    std::filesystem::copy_file(
        testcase_filename, tmp_filename,
        std::filesystem::copy_options::overwrite_existing);

    Vcore* dut = new Vcore();

    // Trace DUMP ON
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;

    dut->trace(tfp, 100);  // Trace 100 levels of hierarchy
    tfp->open(WAVEFORM_FILE);

    // Format
    dut->rst_n = 0;
    dut->clk = 0;

    for (int time_counter = 0; time_counter < TIME_MAX; time_counter++) {
        if (time_counter == 100) {
            dut->rst_n = 1;
        }

        if ((time_counter % 5) == 0) {
            dut->clk = !dut->clk;  // Toggle clock
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

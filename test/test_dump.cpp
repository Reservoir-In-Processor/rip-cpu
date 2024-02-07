#include <filesystem>
#include <fstream>

#include <verilated.h>
#include "Vcore.h"
#include <verilated_vcd_c.h>

#include <gtest/gtest.h>

namespace {

constexpr int TIME_MAX = 6000000;
const char* WAVEFORM_FILE = "simx.vcd";
TEST(TestCore, ExportWaveform) {
    // Instantiate DUT
    std::string testcase_filename = "../../hex/dhry.hex";
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

    // pass $value$plusargs to the simulator
    std::string plusargs = "+dump=dump.txt";
    char *argv[] = {const_cast<char *>(testcase_filename.c_str()),
                    const_cast<char *>(plusargs.c_str())};
    Verilated::commandArgs(2, argv);

    // Format
    dut->sys_rst_n = 0;
    dut->clk = 0;
    dut->run = 0;

    constexpr int TIME_START = 100;
    for (int time_counter = 0; time_counter < TIME_MAX; time_counter++) {
        if (time_counter == 50) {
            dut->sys_rst_n = 1;
            dut->mem_head = 0;
            dut->ret_head = 0;
        }
        if (time_counter == TIME_START) {
            dut->run = 1;
        }
        if (time_counter == TIME_START + 10) {
            dut->run = 0;
        }
        if ((time_counter % 5) == 0) {
            dut->clk = !dut->clk;  // Toggle clock
        }

        // Evaluate DUT
        dut->eval();
        tfp->dump(time_counter);

        if (time_counter > TIME_START && !dut->busy) {
            break;
        }
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

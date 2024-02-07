#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include <verilated.h>
#include "Vcore.h"
#include <verilated_vcd_c.h>

#include <gtest/gtest.h>

class RiscvTests : public ::testing::TestWithParam<std::string> {};

std::vector<std::string> getBinFilesWithPrefix(const std::string &directory,
                                               const std::string &prefix) {
    std::vector<std::string> binFiles;

    for (const auto &entry : std::filesystem::directory_iterator(directory)) {
        if (entry.is_regular_file() && entry.path().extension() == ".hex" &&
            entry.path().filename().string().substr(0, prefix.size()) ==
                prefix) {
            binFiles.push_back(entry.path().string());
        }
    }

    return binFiles;
}

TEST_P(RiscvTests, RiscvTests) {
    constexpr int TIME_MAX = 100000;

    // Instantiate DUT
    std::string testcase_filename = GetParam();
    std::string tmp_filename = "../../hex/testcase.hex";
    std::filesystem::copy_file(
        testcase_filename, tmp_filename,
        std::filesystem::copy_options::overwrite_existing);

    Vcore *dut = new Vcore();

    // Trace DUMP ON
    std::string waveform_dir = "../dump";
    std::string testcase_name = testcase_filename.substr(
        testcase_filename.find_last_of("/") + 1);
    std::string waveform_filename =
        waveform_dir + "/" + testcase_name + ".vcd";
    if (!std::filesystem::exists(waveform_dir)) {
        std::filesystem::create_directory(waveform_dir);
    }

    // pass $value$plusargs to the simulator
    std::string dump_filename = "../dump/" + testcase_name + ".txt";
    std::string plusargs = "+dump=" + dump_filename;
    char *argv[] = {const_cast<char *>(testcase_filename.c_str()),
                    const_cast<char *>(plusargs.c_str())};
    Verilated::commandArgs(2, argv);

    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    dut->trace(tfp, 100);  // Trace 100 levels of hierarchy
    tfp->open(waveform_filename.c_str());

    // Evaluate DUT
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

        dut->eval();
        tfp->dump(time_counter);

        if (time_counter > TIME_START && !dut->busy) {
            break;
        }
    }

    EXPECT_EQ(dut->riscv_tests_passed, 1);

    dut->final();
    tfp->close();
    delete dut;
    delete tfp;
    std::filesystem::remove(tmp_filename);
}
INSTANTIATE_TEST_SUITE_P(RV32I, RiscvTests,
                         ::testing::ValuesIn(getBinFilesWithPrefix(
                             "../../hex/riscv-tests", "rv32ui-p-")));
INSTANTIATE_TEST_SUITE_P(RV32M, RiscvTests,
                         ::testing::ValuesIn(getBinFilesWithPrefix(
                             "../../hex/riscv-tests", "rv32um-p-")));

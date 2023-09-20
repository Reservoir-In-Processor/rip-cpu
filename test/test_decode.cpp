#include "test_decode.hpp"

#include <gtest/gtest.h>
#include <verilated.h>

#include <cstring>
#include <string>

#include "test_inst.hpp"

void VdecodeForTest::set_inst_code(uint32_t inst_code) {
    RST_N = 1;
    CLK = 0;
    READY = 1;
    INST_CODE = inst_code;
    eval();

    // positive edge
    CLK = 1;
    eval();

    std::memcpy(&inst_bit, &INST, sizeof(INST_BIT));
    inst.init(inst_bit);
}

class TestDecode : public ::testing::Test {
   protected:
    VdecodeForTest* dut;

    void SetUp() override { dut = new VdecodeForTest(); }

    void TearDown() override {
        dut->final();
        delete dut;
    }
};

namespace {

TEST_F(TestDecode, Lui) {
    dut->set_inst_code(0x123450B7);  // lui x1, 0x12345000

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 1);
    EXPECT_EQ(dut->IMM, 0x12345000);

    EXPECT_EQ(dut->inst.get_inst_name(), "LUI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Auipc) {
    dut->set_inst_code(0x12345097);  // auipc x1, 0x12345000

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 1);
    EXPECT_EQ(dut->IMM, 0x12345000);

    EXPECT_EQ(dut->inst.get_inst_name(), "AUIPC");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Jal) {
    dut->set_inst_code(0xF7DFF0EF);  // jal x1, -132

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 1);
    EXPECT_EQ(dut->IMM, -132);

    EXPECT_EQ(dut->inst.get_inst_name(), "JAL");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Jalr) {
    dut->set_inst_code(0xFEC08167);  // jalr x2, -20(x1)

    EXPECT_EQ(dut->RS1_NUM, 1);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 2);
    EXPECT_EQ(dut->IMM, -20);

    EXPECT_EQ(dut->inst.get_inst_name(), "JALR");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Beq) {
    dut->set_inst_code(0x00C50563);  // beq x10, x12, 10

    EXPECT_EQ(dut->RS1_NUM, 10);
    EXPECT_EQ(dut->RS2_NUM, 12);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, 10);

    EXPECT_EQ(dut->inst.get_inst_name(), "BEQ");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Bne) {
    dut->set_inst_code(0x00C51563);  // bne x10, x12, 10

    EXPECT_EQ(dut->RS1_NUM, 10);
    EXPECT_EQ(dut->RS2_NUM, 12);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, 10);

    EXPECT_EQ(dut->inst.get_inst_name(), "BNE");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Blt) {
    dut->set_inst_code(0x00C54563);  // blt x10, x12, 10

    EXPECT_EQ(dut->RS1_NUM, 10);
    EXPECT_EQ(dut->RS2_NUM, 12);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, 10);

    EXPECT_EQ(dut->inst.get_inst_name(), "BLT");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Bge) {
    dut->set_inst_code(0x00C55563);  // bge x10, x12, 10

    EXPECT_EQ(dut->RS1_NUM, 10);
    EXPECT_EQ(dut->RS2_NUM, 12);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, 10);

    EXPECT_EQ(dut->inst.get_inst_name(), "BGE");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Bltu) {
    dut->set_inst_code(0x00C56563);  // bltu x10, x12, 10

    EXPECT_EQ(dut->RS1_NUM, 10);
    EXPECT_EQ(dut->RS2_NUM, 12);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, 10);

    EXPECT_EQ(dut->inst.get_inst_name(), "BLTU");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Bgeu) {
    dut->set_inst_code(0x00C57563);  // bgeu x10, x12, 10

    EXPECT_EQ(dut->RS1_NUM, 10);
    EXPECT_EQ(dut->RS2_NUM, 12);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, 10);

    EXPECT_EQ(dut->inst.get_inst_name(), "BGEU");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Lb) {
    dut->set_inst_code(0xFEC40703);  // lb x14, -20(x8)

    EXPECT_EQ(dut->RS1_NUM, 8);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 14);
    EXPECT_EQ(dut->IMM, -20);

    EXPECT_EQ(dut->inst.get_inst_name(), "LB");
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC")); // temporary implementation
}

TEST_F(TestDecode, Lh) {
    dut->set_inst_code(0xFEC41703);  // lh x14, -20(x8)

    EXPECT_EQ(dut->RS1_NUM, 8);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 14);
    EXPECT_EQ(dut->IMM, -20);

    EXPECT_EQ(dut->inst.get_inst_name(), "LH");
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC")); // temporary implementation
}

TEST_F(TestDecode, Lw) {
    dut->set_inst_code(0xFEC42703);  // lw x14, -20(x8)

    EXPECT_EQ(dut->RS1_NUM, 8);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 14);
    EXPECT_EQ(dut->IMM, -20);

    EXPECT_EQ(dut->inst.get_inst_name(), "LW");
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC")); // temporary implementation
}

TEST_F(TestDecode, Lbu) {
    dut->set_inst_code(0xFEC44703);  // lbu x14, -20(x8)

    EXPECT_EQ(dut->RS1_NUM, 8);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 14);
    EXPECT_EQ(dut->IMM, -20);

    EXPECT_EQ(dut->inst.get_inst_name(), "LBU");
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC")); // temporary implementation
}

TEST_F(TestDecode, Lhu) {
    dut->set_inst_code(0xFEC45703);  // lhu x14, -20(x8)

    EXPECT_EQ(dut->RS1_NUM, 8);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 14);
    EXPECT_EQ(dut->IMM, -20);

    EXPECT_EQ(dut->inst.get_inst_name(), "LHU");
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC")); // temporary implementation
}

TEST_F(TestDecode, Sb) {
    dut->set_inst_code(0xFEC48723);  // sb x12, -18(x9)

    EXPECT_EQ(dut->RS1_NUM, 9);
    EXPECT_EQ(dut->RS2_NUM, 12);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, -18);

    EXPECT_EQ(dut->inst.get_inst_name(), "SB");
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Sh) {
    dut->set_inst_code(0xFEC49723);  // sh x12, -18(x9)

    EXPECT_EQ(dut->RS1_NUM, 9);
    EXPECT_EQ(dut->RS2_NUM, 12);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, -18);

    EXPECT_EQ(dut->inst.get_inst_name(), "SH");
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Sw) {
    dut->set_inst_code(0xFEC4A723);  // sw x12, -18(x9)

    EXPECT_EQ(dut->RS1_NUM, 9);
    EXPECT_EQ(dut->RS2_NUM, 12);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, -18);

    EXPECT_EQ(dut->inst.get_inst_name(), "SW");
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Addi) {
    dut->set_inst_code(0x02010413);  // addi x8, x2, 32

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 8);
    EXPECT_EQ(dut->IMM, 32);

    EXPECT_EQ(dut->inst.get_inst_name(), "ADDI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Slti) {
    dut->set_inst_code(0x02012413);  // slti x8, x2, 32

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 8);
    EXPECT_EQ(dut->IMM, 32);

    EXPECT_EQ(dut->inst.get_inst_name(), "SLTI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Sltiu) {
    dut->set_inst_code(0x02013413);  // sltiu x8, x2, 32

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 8);
    EXPECT_EQ(dut->IMM, 32);

    EXPECT_EQ(dut->inst.get_inst_name(), "SLTIU");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Xori) {
    dut->set_inst_code(0x02014413);  // xori x8, x2, 32

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 8);
    EXPECT_EQ(dut->IMM, 32);

    EXPECT_EQ(dut->inst.get_inst_name(), "XORI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Ori) {
    dut->set_inst_code(0x02016413);  // ori x8, x2, 32

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 8);
    EXPECT_EQ(dut->IMM, 32);

    EXPECT_EQ(dut->inst.get_inst_name(), "ORI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Andi) {
    dut->set_inst_code(0x02017413);  // andi x8, x2, 32

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 8);
    EXPECT_EQ(dut->IMM, 32);

    EXPECT_EQ(dut->inst.get_inst_name(), "ANDI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Slli) {
    dut->set_inst_code(0x00911413);  // slli x8, x2, 9

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 8);
    EXPECT_EQ(dut->IMM, 9);

    EXPECT_EQ(dut->inst.get_inst_name(), "SLLI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Srli) {
    dut->set_inst_code(0x00915413);  // srli x8, x2, 9

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 8);
    EXPECT_EQ(dut->IMM, 9);

    EXPECT_EQ(dut->inst.get_inst_name(), "SRLI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Srai) {
    dut->set_inst_code(0x40915413);  // srai x8, x2, 9

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 8);
    EXPECT_EQ(dut->IMM, 9);

    EXPECT_EQ(dut->inst.get_inst_name(), "SRAI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Add) {
    dut->set_inst_code(0x00320333);  // add x6, x4, x3

    EXPECT_EQ(dut->RS1_NUM, 4);
    EXPECT_EQ(dut->RS2_NUM, 3);
    EXPECT_EQ(dut->RD_NUM, 6);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "ADD");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Sub) {
    dut->set_inst_code(0x40320333);  // sub x6, x4, x3

    EXPECT_EQ(dut->RS1_NUM, 4);
    EXPECT_EQ(dut->RS2_NUM, 3);
    EXPECT_EQ(dut->RD_NUM, 6);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "SUB");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Sll) {
    dut->set_inst_code(0x00321333);  // sll x6, x4, x3

    EXPECT_EQ(dut->RS1_NUM, 4);
    EXPECT_EQ(dut->RS2_NUM, 3);
    EXPECT_EQ(dut->RD_NUM, 6);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "SLL");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Slt) {
    dut->set_inst_code(0x00322333);  // slt x6, x4, x3

    EXPECT_EQ(dut->RS1_NUM, 4);
    EXPECT_EQ(dut->RS2_NUM, 3);
    EXPECT_EQ(dut->RD_NUM, 6);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "SLT");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Sltu) {
    dut->set_inst_code(0x00323333);  // sltu x6, x4, x3

    EXPECT_EQ(dut->RS1_NUM, 4);
    EXPECT_EQ(dut->RS2_NUM, 3);
    EXPECT_EQ(dut->RD_NUM, 6);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "SLTU");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Xor) {
    dut->set_inst_code(0x00324333);  // xor x6, x4, x3

    EXPECT_EQ(dut->RS1_NUM, 4);
    EXPECT_EQ(dut->RS2_NUM, 3);
    EXPECT_EQ(dut->RD_NUM, 6);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "XOR");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Srl) {
    dut->set_inst_code(0x00325333);  // srl x6, x4, x3

    EXPECT_EQ(dut->RS1_NUM, 4);
    EXPECT_EQ(dut->RS2_NUM, 3);
    EXPECT_EQ(dut->RD_NUM, 6);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "SRL");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Sra) {
    dut->set_inst_code(0x40325333);  // sra x6, x4, x3

    EXPECT_EQ(dut->RS1_NUM, 4);
    EXPECT_EQ(dut->RS2_NUM, 3);
    EXPECT_EQ(dut->RD_NUM, 6);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "SRA");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Or) {
    dut->set_inst_code(0x00326333);  // or x6, x4, x3

    EXPECT_EQ(dut->RS1_NUM, 4);
    EXPECT_EQ(dut->RS2_NUM, 3);
    EXPECT_EQ(dut->RD_NUM, 6);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "OR");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, And) {
    dut->set_inst_code(0x00327333);  // and x6, x4, x3

    EXPECT_EQ(dut->RS1_NUM, 4);
    EXPECT_EQ(dut->RS2_NUM, 3);
    EXPECT_EQ(dut->RD_NUM, 6);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "AND");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Fence) {
    dut->set_inst_code(0x0FF0000F);  // fence iorw, iorw

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "FENCE");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, FenceI) {
    dut->set_inst_code(0x0000100F);  // fence.i

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "FENCE_I");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Ecall) {
    dut->set_inst_code(0x00000073);  // ecall

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "ECALL");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Ebreak) {
    dut->set_inst_code(0x00100073);  // ebreak

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "EBREAK");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Csrrw) {
    dut->set_inst_code(0x342110F3);  // csrrw x1, 834, x2

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 1);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->CSR_NUM, 834);
    EXPECT_EQ(dut->CSR_ZIMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "CSRRW");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Csrrs) {
    dut->set_inst_code(0x342120F3);  // csrrs x1, 834, x2

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 1);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->CSR_NUM, 834);
    EXPECT_EQ(dut->CSR_ZIMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "CSRRS");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Csrrc) {
    dut->set_inst_code(0x342130F3);  // csrrc x1, 834, x2

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 1);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->CSR_NUM, 834);
    EXPECT_EQ(dut->CSR_ZIMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "CSRRC");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Csrrwi) {
    dut->set_inst_code(0x342150F3);  // csrrwi x1, 834, 2

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 1);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->CSR_NUM, 834);
    EXPECT_EQ(dut->CSR_ZIMM, 2);

    EXPECT_EQ(dut->inst.get_inst_name(), "CSRRWI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Csrrsi) {
    dut->set_inst_code(0x342160F3);  // csrrsi x1, 834, 2

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 1);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->CSR_NUM, 834);
    EXPECT_EQ(dut->CSR_ZIMM, 2);

    EXPECT_EQ(dut->inst.get_inst_name(), "CSRRSI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, Csrrci) {
    dut->set_inst_code(0x342170F3);  // csrrci x1, 834, 2

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 1);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->CSR_NUM, 834);
    EXPECT_EQ(dut->CSR_ZIMM, 2);

    EXPECT_EQ(dut->inst.get_inst_name(), "CSRRCI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, AddiNoRegUpdate) {
    dut->set_inst_code(0x00000013);  // addi x0, x0, 0 (NOP)

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 0);
    EXPECT_EQ(dut->IMM, 0);

    EXPECT_EQ(dut->inst.get_inst_name(), "ADDI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

TEST_F(TestDecode, AddiSignalTiming) {
    dut->RST_N = 1;
    dut->CLK = 0;
    dut->READY = 1;
    dut->INST_CODE = 0x02010413;  // addi x8, x2, 32
    dut->eval();

    EXPECT_EQ(dut->RS1_NUM, 2);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 8);

    // positive edge
    dut->CLK = 1;
    dut->eval();
    std::memcpy(&dut->inst_bit, &dut->INST, sizeof(INST_BIT));
    dut->inst.init(dut->inst_bit);

    EXPECT_EQ(dut->IMM, 32);
    EXPECT_EQ(dut->inst.get_inst_name(), "ADDI");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_TRUE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));

    // negative edge
    dut->CLK = 0;
    dut->READY = 0;
    dut->eval();

    EXPECT_EQ(dut->RS1_NUM, 0);
    EXPECT_EQ(dut->RS2_NUM, 0);
    EXPECT_EQ(dut->RD_NUM, 0);

    // positive edge
    dut->CLK = 1;
    dut->eval();
    std::memcpy(&dut->inst_bit, &dut->INST, sizeof(INST_BIT));
    dut->inst.init(dut->inst_bit);

    EXPECT_EQ(dut->IMM, 0);
    EXPECT_EQ(dut->inst.get_inst_name(), "NOP");
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("ACCESS_MEM"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_REG"));
    EXPECT_FALSE(dut->inst.ctrl_signal_map.at("UPDATE_PC"));
}

}  // namespace

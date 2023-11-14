
#include "test_alu.hpp"

#include <gtest/gtest.h>
#include <verilated.h>

#include <climits>
#include <cstring>
#include <random>
#include <string>

#include "test_inst.hpp"

void ValuForTest::exec(const inst_bit_t &_inst_bit, const int &_rs1,
                       const int &_rs2, const int &_pc, const int &_csr,
                       const int &_imm, const unsigned char &_zimm) {
  rst_n = 1;
  clk = 0;

  std::memcpy(&inst, &_inst_bit, sizeof(inst_bit_t));

  rs1 = _rs1;
  rs2 = _rs2;
  pc = _pc;
  csr = _csr;
  imm = _imm;
  zimm = _zimm;
  eval();

  // positive edge
  clk = 1;
  eval();
}

class TestAlu : public ::testing::Test {
protected:
  TestAlu()
      : engine(seed_gen()), dist_int(INT_MIN, INT_MAX), dist_5bit(0, 31) {}
  ValuForTest *dut;

  std::random_device seed_gen;
  std::mt19937_64 engine;
  std::uniform_int_distribution<int> dist_int;
  std::uniform_int_distribution<unsigned char> dist_5bit;

  inst_bit_t inst_bit;
  int rs1;
  int rs2;
  int pc;
  int csr;
  int imm;
  unsigned char zimm;

  void SetUp() override { dut = new ValuForTest(); }

  void TearDown() override {
    dut->final();
    delete dut;
  }
};

namespace {
const unsigned N = 10;
TEST_F(TestAlu, Lui) {
  inst_bit_t inst_bit = {0};
  inst_bit.LUI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, imm);
  }
}

TEST_F(TestAlu, Auipc) {
  inst_bit_t inst_bit = {0};
  inst_bit.AUIPC = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, pc + imm);
  }
}

TEST_F(TestAlu, Jal) {
  inst_bit_t inst_bit = {0};
  inst_bit.JAL = 1;
  inst_bit.UPDATE_PC = 1;

  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, pc + 4);
  }
}

TEST_F(TestAlu, Jalr) {
  inst_bit_t inst_bit = {0};
  inst_bit.JALR = 1;
  inst_bit.UPDATE_PC = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, pc + 4);
  }
}

TEST_F(TestAlu, Beq) {
  inst_bit_t inst_bit = {0};
  inst_bit.BEQ = 1;
  inst_bit.UPDATE_PC = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 == rs2);
  }
}

TEST_F(TestAlu, Bne) {
  inst_bit_t inst_bit = {0};
  inst_bit.BNE = 1;
  inst_bit.UPDATE_PC = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 != rs2);
  }
}

TEST_F(TestAlu, Blt) {
  inst_bit_t inst_bit = {0};
  inst_bit.BLT = 1;
  inst_bit.UPDATE_PC = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 < rs2);
  }
}

TEST_F(TestAlu, Bge) {
  inst_bit_t inst_bit = {0};
  inst_bit.BGE = 1;
  inst_bit.UPDATE_PC = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 >= rs2);
  }
}

TEST_F(TestAlu, Bltu) {
  inst_bit_t inst_bit = {0};
  inst_bit.BLTU = 1;
  inst_bit.UPDATE_PC = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, (unsigned)rs1 < (unsigned)rs2);
  }
}

TEST_F(TestAlu, Bgeu) {
  inst_bit_t inst_bit = {0};
  inst_bit.BGEU = 1;
  inst_bit.UPDATE_PC = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, (unsigned)rs1 >= (unsigned)rs2);
  }
}

TEST_F(TestAlu, Lb) {
  inst_bit_t inst_bit = {0};
  inst_bit.BGEU = 1;
  inst_bit.ACCESS_MEM = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 + imm);
  }
}

TEST_F(TestAlu, Lh) {
  inst_bit_t inst_bit = {0};
  inst_bit.LH = 1;
  inst_bit.ACCESS_MEM = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 + imm);
  }
}

TEST_F(TestAlu, Lw) {
  inst_bit_t inst_bit = {0};
  inst_bit.LW = 1;
  inst_bit.ACCESS_MEM = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 + imm);
  }
}

TEST_F(TestAlu, Lbu) {
  inst_bit_t inst_bit = {0};
  inst_bit.LBU = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 + imm);
  }
}

TEST_F(TestAlu, Lhu) {
  inst_bit_t inst_bit = {0};
  inst_bit.LHU = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 + imm);
  }
}

TEST_F(TestAlu, Sb) {
  inst_bit_t inst_bit = {0};
  inst_bit.SB = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 + imm);
  }
}

TEST_F(TestAlu, Sh) {
  inst_bit_t inst_bit = {0};
  inst_bit.SH = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 + imm);
  }
}

TEST_F(TestAlu, Sw) {
  inst_bit_t inst_bit = {0};
  inst_bit.SW = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 + imm);
  }
}

TEST_F(TestAlu, Addi) {
  inst_bit_t inst_bit = {0};
  inst_bit.ADDI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 + imm);
  }
}

TEST_F(TestAlu, Slti) {
  inst_bit_t inst_bit = {0};
  inst_bit.SLTI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 < imm);
  }
}

TEST_F(TestAlu, Sltiu) {
  inst_bit_t inst_bit = {0};
  inst_bit.SLTIU = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, (unsigned)rs1 < (unsigned)imm);
  }
}

TEST_F(TestAlu, Xori) {
  inst_bit_t inst_bit = {0};
  inst_bit.XORI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 ^ imm);
  }
}

TEST_F(TestAlu, Ori) {
  inst_bit_t inst_bit = {0};
  inst_bit.ORI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 | imm);
  }
}

TEST_F(TestAlu, Andi) {
  inst_bit_t inst_bit = {0};
  inst_bit.ANDI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 & imm);
  }
}

TEST_F(TestAlu, Slli) {
  inst_bit_t inst_bit = {0};
  inst_bit.SLLI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 << (imm & 0x1f));
  }
}

TEST_F(TestAlu, Srli) {
  inst_bit_t inst_bit = {0};
  inst_bit.SRLI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    unsigned shamt = (imm & 0x1f);
    EXPECT_EQ(dut->rslt, (unsigned)rs1 >> shamt);
  }
}

TEST_F(TestAlu, Srai) {
  inst_bit_t inst_bit = {0};
  inst_bit.SRAI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    unsigned shamt = (imm & 0x1f);
    EXPECT_EQ(dut->rslt, rs1 >> shamt);
  }
}

TEST_F(TestAlu, Add) {
  inst_bit_t inst_bit = {0};
  inst_bit.ADD = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 + rs2);
  }
}

TEST_F(TestAlu, Sub) {
  inst_bit_t inst_bit = {0};
  inst_bit.SUB = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 - rs2);
  }
}

TEST_F(TestAlu, Sll) {
  inst_bit_t inst_bit = {0};
  inst_bit.SLL = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    unsigned shamt = rs2 & 0x1f;
    EXPECT_EQ(dut->rslt, rs1 << shamt);
  }
}

TEST_F(TestAlu, Slt) {
  inst_bit_t inst_bit = {0};
  inst_bit.SLT = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 < rs2);
  }
}

TEST_F(TestAlu, Sltu) {
  inst_bit_t inst_bit = {0};
  inst_bit.SLTU = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, (unsigned)rs1 < (unsigned)rs2);
  }
}

TEST_F(TestAlu, Xor) {
  inst_bit_t inst_bit = {0};
  inst_bit.XOR = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 ^ rs2);
  }
}

TEST_F(TestAlu, Srl) {
  inst_bit_t inst_bit = {0};
  inst_bit.SRL = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    unsigned shamt = rs2 & 0x1f;
    EXPECT_EQ(dut->rslt, (unsigned)rs1 >> shamt);
  }
}

TEST_F(TestAlu, Sra) {
  inst_bit_t inst_bit = {0};
  inst_bit.SRA = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    unsigned shamt = rs2 & 0x1f;
    EXPECT_EQ(dut->rslt, rs1 >> shamt);
  }
}

TEST_F(TestAlu, Or) {
  inst_bit_t inst_bit = {0};
  inst_bit.OR = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 | rs2);
  }
}

TEST_F(TestAlu, And) {}

TEST_F(TestAlu, Fence) {
  inst_bit_t inst_bit = {0};
  inst_bit.FENCE = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    // FIXME: what is expected?
    EXPECT_EQ(dut->rslt, 0);
  }
}

TEST_F(TestAlu, FenceI) {
  inst_bit_t inst_bit = {0};
  inst_bit.FENCE_I = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    // FIXME: what is expected?
    EXPECT_EQ(dut->rslt, 0);
  }
}

TEST_F(TestAlu, Ecall) {
  inst_bit_t inst_bit = {0};
  inst_bit.ECALL = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    // FIXME: what is expected?
    EXPECT_EQ(dut->rslt, 0);
  }
}

TEST_F(TestAlu, Ebreak) {
  inst_bit_t inst_bit = {0};
  inst_bit.ECALL = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    // FIXME: what is expected?
    EXPECT_EQ(dut->rslt, 0);
  }
}

TEST_F(TestAlu, Csrrw) {
  inst_bit_t inst_bit = {0};
  inst_bit.CSRRW = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1);
  }
}

TEST_F(TestAlu, Csrrs) {
  inst_bit_t inst_bit = {0};
  inst_bit.CSRRS = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    EXPECT_EQ(dut->rslt, rs1 | csr);
  }
}

TEST_F(TestAlu, Csrrc) {
  inst_bit_t inst_bit = {0};
  inst_bit.CSRRS = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    // FIXME: what is expected?
    EXPECT_EQ(dut->rslt, ~rs1 & csr);
  }
}

TEST_F(TestAlu, Csrrwi) {
  inst_bit_t inst_bit = {0};
  inst_bit.CSRRWI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    // FIXME: what is expected?
    EXPECT_EQ(dut->rslt, zimm);
  }
}

TEST_F(TestAlu, Csrrsi) {
  inst_bit_t inst_bit = {0};
  inst_bit.CSRRSI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    // FIXME: what is expected?
    EXPECT_EQ(dut->rslt, zimm | csr);
  }
}

TEST_F(TestAlu, Csrrci) {
  inst_bit_t inst_bit = {0};
  inst_bit.CSRRCI = 1;
  for (int i = 0; i < N; ++i) {
    rs1 = dist_int(engine);
    rs2 = dist_int(engine);
    pc = dist_int(engine);
    csr = dist_int(engine);
    imm = dist_int(engine);
    zimm = dist_5bit(engine);

    dut->exec(inst_bit, rs1, rs2, pc, csr, imm, zimm);
    // FIXME: what is expected?
    EXPECT_EQ(dut->rslt, ~zimm & csr);
  }
}

} // namespace

#include "test_inst.hpp"

#include <gtest/gtest.h>

#include <cstring>

Inst::Inst() {}
Inst::Inst(const INST_BIT& _inst_bit) { init(_inst_bit); }

Inst::~Inst() {}

void Inst::init(const INST_BIT& _inst_bit) {
    inst_bit = _inst_bit;
    ctrl_signal_map = {
        // pipeline control signals
        {"UPDATE_PC", (bool)inst_bit.UPDATE_PC},
        {"UPDATE_REG", (bool)inst_bit.UPDATE_REG},
        {"ACCESS_MEM", (bool)inst_bit.ACCESS_MEM},
    };
    inst_map = {
        // RV32I
        {"CSRRCI", (bool)inst_bit.CSRRCI},   {"CSRRSI", (bool)inst_bit.CSRRSI},
        {"CSRRWI", (bool)inst_bit.CSRRWI},   {"CSRRC", (bool)inst_bit.CSRRC},
        {"CSRRS", (bool)inst_bit.CSRRS},     {"CSRRW", (bool)inst_bit.CSRRW},
        {"EBREAK", (bool)inst_bit.EBREAK},   {"ECALL", (bool)inst_bit.ECALL},
        {"FENCE_I", (bool)inst_bit.FENCE_I}, {"FENCE", (bool)inst_bit.FENCE},
        {"AND", (bool)inst_bit.AND},         {"OR", (bool)inst_bit.OR},
        {"SRA", (bool)inst_bit.SRA},         {"SRL", (bool)inst_bit.SRL},
        {"XOR", (bool)inst_bit.XOR},         {"SLTU", (bool)inst_bit.SLTU},
        {"SLT", (bool)inst_bit.SLT},         {"SLL", (bool)inst_bit.SLL},
        {"SUB", (bool)inst_bit.SUB},         {"ADD", (bool)inst_bit.ADD},
        {"SRAI", (bool)inst_bit.SRAI},       {"SRLI", (bool)inst_bit.SRLI},
        {"SLLI", (bool)inst_bit.SLLI},       {"ANDI", (bool)inst_bit.ANDI},
        {"ORI", (bool)inst_bit.ORI},         {"XORI", (bool)inst_bit.XORI},
        {"SLTIU", (bool)inst_bit.SLTIU},     {"SLTI", (bool)inst_bit.SLTI},
        {"ADDI", (bool)inst_bit.ADDI},       {"SW", (bool)inst_bit.SW},
        {"SH", (bool)inst_bit.SH},           {"SB", (bool)inst_bit.SB},
        {"LHU", (bool)inst_bit.LHU},         {"LBU", (bool)inst_bit.LBU},
        {"LW", (bool)inst_bit.LW},           {"LH", (bool)inst_bit.LH},
        {"LB", (bool)inst_bit.LB},           {"BGEU", (bool)inst_bit.BGEU},
        {"BLTU", (bool)inst_bit.BLTU},       {"BGE", (bool)inst_bit.BGE},
        {"BLT", (bool)inst_bit.BLT},         {"BNE", (bool)inst_bit.BNE},
        {"BEQ", (bool)inst_bit.BEQ},         {"JALR", (bool)inst_bit.JALR},
        {"JAL", (bool)inst_bit.JAL},         {"AUIPC", (bool)inst_bit.AUIPC},
        {"LUI", (bool)inst_bit.LUI},
    };
}

std::string Inst::get_inst_name() {
    std::string inst_name = "NOP";
    for (auto itr = inst_map.begin(); itr != inst_map.end(); ++itr) {
        if (itr->second) {
            if (inst_name == "NOP") {
                inst_name = itr->first;
            } else {
                inst_name += " " + itr->first;
            }
        }
    }
    return inst_name;
}

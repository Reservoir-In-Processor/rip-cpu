#include "test_inst.hpp"

#include <gtest/gtest.h>

#include <cstring>

Inst::Inst() {}
Inst::Inst(const inst_bit_t& inst_bit) { init(inst_bit); }

Inst::~Inst() {}

void Inst::init(const inst_bit_t& inst_bit) {
    std::memcpy(&_inst_bit, &inst_bit, sizeof(inst_bit_t));
    ctrl_signal_map = {
        // pipeline control signals
        {"UPDATE_PC", (bool)_inst_bit.UPDATE_PC},
        {"UPDATE_REG", (bool)_inst_bit.UPDATE_REG},
        {"UPDATE_CSR", (bool)_inst_bit.UPDATE_CSR},
        {"ACCESS_MEM", (bool)_inst_bit.ACCESS_MEM},
    };
    _inst_map = {
        // RV32I
        {"CSRRCI", (bool)_inst_bit.CSRRCI},
        {"CSRRSI", (bool)_inst_bit.CSRRSI},
        {"CSRRWI", (bool)_inst_bit.CSRRWI},
        {"CSRRC", (bool)_inst_bit.CSRRC},
        {"CSRRS", (bool)_inst_bit.CSRRS},
        {"CSRRW", (bool)_inst_bit.CSRRW},
        {"MRET", (bool)_inst_bit.MRET},
        {"EBREAK", (bool)_inst_bit.EBREAK},
        {"ECALL", (bool)_inst_bit.ECALL},
        {"FENCE_I", (bool)_inst_bit.FENCE_I},
        {"FENCE", (bool)_inst_bit.FENCE},
        {"AND", (bool)_inst_bit.AND},
        {"OR", (bool)_inst_bit.OR},
        {"SRA", (bool)_inst_bit.SRA},
        {"SRL", (bool)_inst_bit.SRL},
        {"XOR", (bool)_inst_bit.XOR},
        {"SLTU", (bool)_inst_bit.SLTU},
        {"SLT", (bool)_inst_bit.SLT},
        {"SLL", (bool)_inst_bit.SLL},
        {"SUB", (bool)_inst_bit.SUB},
        {"ADD", (bool)_inst_bit.ADD},
        {"SRAI", (bool)_inst_bit.SRAI},
        {"SRLI", (bool)_inst_bit.SRLI},
        {"SLLI", (bool)_inst_bit.SLLI},
        {"ANDI", (bool)_inst_bit.ANDI},
        {"ORI", (bool)_inst_bit.ORI},
        {"XORI", (bool)_inst_bit.XORI},
        {"SLTIU", (bool)_inst_bit.SLTIU},
        {"SLTI", (bool)_inst_bit.SLTI},
        {"ADDI", (bool)_inst_bit.ADDI},
        {"SW", (bool)_inst_bit.SW},
        {"SH", (bool)_inst_bit.SH},
        {"SB", (bool)_inst_bit.SB},
        {"LHU", (bool)_inst_bit.LHU},
        {"LBU", (bool)_inst_bit.LBU},
        {"LW", (bool)_inst_bit.LW},
        {"LH", (bool)_inst_bit.LH},
        {"LB", (bool)_inst_bit.LB},
        {"BGEU", (bool)_inst_bit.BGEU},
        {"BLTU", (bool)_inst_bit.BLTU},
        {"BGE", (bool)_inst_bit.BGE},
        {"BLT", (bool)_inst_bit.BLT},
        {"BNE", (bool)_inst_bit.BNE},
        {"BEQ", (bool)_inst_bit.BEQ},
        {"JALR", (bool)_inst_bit.JALR},
        {"JAL", (bool)_inst_bit.JAL},
        {"AUIPC", (bool)_inst_bit.AUIPC},
        {"LUI", (bool)_inst_bit.LUI},

        // RV32M
        {"MUL", (bool)_inst_bit.MUL},
        {"MULH", (bool)_inst_bit.MULH},
        {"MULHSU", (bool)_inst_bit.MULHSU},
        {"MULHU", (bool)_inst_bit.MULHU},
        {"DIV", (bool)_inst_bit.DIV},
        {"DIVU", (bool)_inst_bit.DIVU},
        {"REM", (bool)_inst_bit.REM},
        {"REMU", (bool)_inst_bit.REMU},

        // Custom
        {"EXTX", (bool)_inst_bit.EXTX},
        {"EXT", (bool)_inst_bit.EXT},
    };
}

std::string Inst::get_inst_name() {
    std::string inst_name = "NOP";
    for (const auto& [op_name, is_active] : _inst_map) {
        if (is_active) {
            if (inst_name == "NOP") {
                inst_name = op_name;
            } else {
                inst_name += " " + op_name;
            }
        }
    }
    return inst_name;
}

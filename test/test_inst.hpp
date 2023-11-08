#ifndef _INSTRUCTIONS_HPP_
#define _INSTRUCTIONS_HPP_

#include <map>
#include <string>

typedef struct {
    // pipeline control signals
    bool UPDATE_PC : 1;
    bool UPDATE_CSR : 1;
    bool UPDATE_REG : 1;
    bool ACCESS_MEM : 1;

    // RV32M
    bool REMU : 1;
    bool REM : 1;
    bool DIVU : 1;
    bool DIV : 1;
    bool MULHU : 1;
    bool MULHSU : 1;
    bool MULH : 1;
    bool MUL : 1;

    // RV32I
    bool CSRRCI : 1;
    bool CSRRSI : 1;
    bool CSRRWI : 1;
    bool CSRRC : 1;
    bool CSRRS : 1;
    bool CSRRW : 1;
    bool MRET : 1;
    bool EBREAK : 1;
    bool ECALL : 1;
    bool FENCE_I : 1;
    bool FENCE : 1;
    bool AND : 1;
    bool OR : 1;
    bool SRA : 1;
    bool SRL : 1;
    bool XOR : 1;
    bool SLTU : 1;
    bool SLT : 1;
    bool SLL : 1;
    bool SUB : 1;
    bool ADD : 1;
    bool SRAI : 1;
    bool SRLI : 1;
    bool SLLI : 1;
    bool ANDI : 1;
    bool ORI : 1;
    bool XORI : 1;
    bool SLTIU : 1;
    bool SLTI : 1;
    bool ADDI : 1;
    bool SW : 1;
    bool SH : 1;
    bool SB : 1;
    bool LHU : 1;
    bool LBU : 1;
    bool LW : 1;
    bool LH : 1;
    bool LB : 1;
    bool BGEU : 1;
    bool BLTU : 1;
    bool BGE : 1;
    bool BLT : 1;
    bool BNE : 1;
    bool BEQ : 1;
    bool JALR : 1;
    bool JAL : 1;
    bool AUIPC : 1;
    bool LUI : 1;
} __attribute__((packed)) inst_bit_t;

class Inst {
   private:
    inst_bit_t _inst_bit;
    std::map<std::string, bool> _inst_map;

   public:
    Inst();
    Inst(const inst_bit_t&);
    ~Inst();

    std::map<std::string, bool> ctrl_signal_map;
    void init(const inst_bit_t&);
    std::string get_inst_name();
};

#endif

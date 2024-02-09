`default_nettype none
`timescale 1ns / 1ps

`ifndef RIP_TYPE
`define RIP_TYPE

// define types
package rip_type;

    typedef struct packed {
        // RV32I
        logic LUI;
        logic AUIPC;
        logic JAL;
        logic JALR;
        logic BEQ;
        logic BNE;
        logic BLT;
        logic BGE;
        logic BLTU;
        logic BGEU;
        logic LB;
        logic LH;
        logic LW;
        logic LBU;
        logic LHU;
        logic SB;
        logic SH;
        logic SW;
        logic ADDI;
        logic SLTI;
        logic SLTIU;
        logic XORI;
        logic ORI;
        logic ANDI;
        logic SLLI;
        logic SRLI;
        logic SRAI;
        logic ADD;
        logic SUB;
        logic SLL;
        logic SLT;
        logic SLTU;
        logic XOR;
        logic SRL;
        logic SRA;
        logic OR;
        logic AND;
        logic FENCE;
        logic FENCE_I;
        logic ECALL;
        logic EBREAK;
        logic MRET;
        logic CSRRW;
        logic CSRRS;
        logic CSRRC;
        logic CSRRWI;
        logic CSRRSI;
        logic CSRRCI;

        // RV32M
        logic MUL;
        logic MULH;
        logic MULHSU;
        logic MULHU;
        logic DIV;
        logic DIVU;
        logic REM;
        logic REMU;

        // Custom
        // opcode  ... 7'b0001011
        // funct12 ... EXTX: 12'b0, EXT: 12'b1
        logic EXTX;
        logic EXT;

        // pipeline control signals
        logic ACCESS_MEM;
        logic UPDATE_REG;
        logic UPDATE_CSR;
        logic UPDATE_PC;
    } inst_t;

    typedef struct packed {
        logic INVALID;
        logic STALL;
        logic READY;
    } state_t;

    typedef struct packed {
        logic [31:0] mstatus;
        logic [31:0] mtvec;
        logic [31:0] mepc;
        logic [31:0] mcause;
    } csr_t;
    
    typedef enum logic [1:0] {
        FINISHED = 2'b00,
        RUNNING  = 2'b01,
        EXITPROC = 2'b10
    } core_mode_t;

endpackage : rip_type

`endif  // RIP_TYPE

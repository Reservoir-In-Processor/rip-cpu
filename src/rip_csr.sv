`default_nettype none
`timescale 1ns / 1ps

typedef struct packed {
    logic [31:0] mstatus;
    logic [31:0] mtvec;
    logic [31:0] mepc;
    logic [31:0] mcause;
} csr_t;

// returns {valid, csr_value}
function static [31:0] read_csr(input csr_t csr, input bit [11:0] csr_num);
    begin
        import rip_const::*;
        case (csr_num)
            MTVEC: read_csr = csr.mtvec;
            MEPC: read_csr = csr.mepc;
            MCAUSE: read_csr = csr.mcause;
            default: read_csr = 32'b0;
        endcase
    end
endfunction : read_csr

// set csr value
task static csr_write(input csr_t csr, input bit [11:0] csr_num, input bit [31:0] csr_value);
    begin
        import rip_const::*;
        case (csr_num)
            MTVEC: csr.mtvec = csr_value;
            MEPC: csr.mepc = csr_value;
            MCAUSE: csr.mcause = csr_value;
            default: ;
        endcase
    end
endtask : csr_write

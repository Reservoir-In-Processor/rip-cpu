`default_nettype none
`timescale 1ns / 1ps

`include "rip_common.sv"

// returns {valid, csr_value}
function static [31:0] read_csr(
    input rip_common::csr_t csr,
    input logic [11:0] csr_num
);
    begin
        import rip_common::*;
        case (csr_num)
            MTVEC: read_csr = csr.mtvec;
            MEPC: read_csr = csr.mepc;
            MCAUSE: read_csr = csr.mcause;
            default: read_csr = 32'b0;
        endcase
    end
endfunction: read_csr

// set csr value
task static write_csr(
    inout rip_common::csr_t csr,
    input logic [11:0] csr_num,
    input logic [31:0] csr_value);
    begin
        import rip_common::*;
        case (csr_num)
            MTVEC: csr.mtvec = csr_value;
            MEPC: csr.mepc = csr_value;
            MCAUSE: csr.mcause = csr_value;
            default: ;
        endcase
    end
endtask: write_csr

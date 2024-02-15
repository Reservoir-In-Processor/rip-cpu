`default_nettype none
`timescale 1ns / 1ps

package rip_csr;
    // returns csr value
    function static logic [31:0] read_csr
    (
        input rip_type::csr_t csr,
        input logic [11:0] csr_num
    );
        begin
            import rip_config::*;
            import rip_type::*;

            case (csr_num)
                MTVEC: read_csr = csr.mtvec;
                MEPC: read_csr = csr.mepc;
                MCAUSE: read_csr = csr.mcause;
                CYCLE: read_csr = csr.cycle;
                BPTP: read_csr = csr.bptp;
                BPTN: read_csr = csr.bptn;
                BPFP: read_csr = csr.bpfp;
                BPFN: read_csr = csr.bpfn;
                default: read_csr = 32'b0;
            endcase
        end
    endfunction: read_csr

    // sets csr value
    task static write_csr(
        inout rip_type::csr_t csr,
        input logic [11:0] csr_num,
        input logic [31:0] csr_value);
        begin
            import rip_config::*;
            import rip_type::*;

            case (csr_num)
                MTVEC: csr.mtvec = csr_value;
                MEPC: csr.mepc = csr_value;
                MCAUSE: csr.mcause = csr_value;
                default: ;
            endcase
        end
    endtask: write_csr
endpackage: rip_csr

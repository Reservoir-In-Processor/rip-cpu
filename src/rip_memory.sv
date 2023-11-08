/*
 * Module `rip_memory`
 *
 * Byte addressing memory system top module.
 */

`default_nettype none
`timescale 1ns / 1ps

`include "rip_common.sv"

module rip_memory (
    input wire clk,

    input wire if_ready,
    input wire [rip_common::DATA_WIDTH-1:0] pc,
    output logic [rip_common::DATA_WIDTH-1:0] if_dout,

    input wire ma_ready,
    input rip_common::inst_t ex_inst,
    input wire [rip_common::DATA_WIDTH-1:0] ex_addr,
    input wire [rip_common::DATA_WIDTH-1:0] ex_din,
    output wire [rip_common::DATA_WIDTH-1:0] ma_dout
);
    import rip_common::*;

    (* ram_style = "block" *)
    reg [rip_common::DATA_WIDTH-1:0] mem_block[1<<rip_common::ADDR_WIDTH];

    logic [rip_common::ADDR_WIDTH-1:0] if_mem_addr;

    logic [rip_common::ADDR_WIDTH-1:0] ex_mem_addr;
    logic [1:0] ex_mem_offset;
    logic [rip_common::NUM_COL-1:0] ex_mem_we;
    logic [rip_common::DATA_WIDTH-1:0] ex_mem_wdata;
    logic [rip_common::DATA_WIDTH-1:0] ma_mem_rdata;

    // initialization
    initial begin
`ifdef VERILATOR
        $readmemh("../../hex/testcase.hex", mem_block);
`else
        $readmemh("../../hex/fib.hex", mem_block);
`endif  // VERILATOR
    end

    // instruction fetch
    always_comb begin
        if_mem_addr = pc[ADDR_WIDTH+1:2];
    end

    always_ff @(posedge clk) begin
        if (if_ready) begin
            if_dout <= mem_block[if_mem_addr];
        end
    end

    // memory access
    always_comb begin
        ex_mem_addr   = ex_addr[ADDR_WIDTH+1:2];
        ex_mem_offset = ex_addr[1:0];

        for (integer i = 0; i < NUM_COL; i = i + 1) begin
            ex_mem_we[i] = ma_ready & ((ex_inst.SB && ex_mem_offset == i[1:0]) |
                                       (ex_inst.SH && ex_mem_offset[1] == i[1]) | ex_inst.SW);
        end

        if (ex_inst.SB) begin
            ex_mem_wdata = {24'd0, ex_din[7:0]} << (ex_mem_offset * B_WIDTH);
        end
        else if (ex_inst.SH) begin
            ex_mem_wdata = {16'd0, ex_din[15:0]} << (ex_mem_offset * B_WIDTH * 2);
        end
        else begin
            ex_mem_wdata = ex_din;
        end

        if (ex_inst.LB) begin
            ma_dout = {
                {24{ma_mem_rdata[ex_mem_offset*B_WIDTH+7]}},
                ma_mem_rdata[ex_mem_offset*B_WIDTH+:B_WIDTH]
            };
        end
        else if (ex_inst.LH) begin
            ma_dout = {
                {16{ma_mem_rdata[ex_mem_offset*B_WIDTH+15]}},
                ma_mem_rdata[ex_mem_offset*B_WIDTH*2+:B_WIDTH*2]
            };
        end
        else if (ex_inst.LBU) begin
            ma_dout = {{24{1'b0}}, ma_mem_rdata[ex_mem_offset*B_WIDTH+:B_WIDTH]};
        end
        else if (ex_inst.LHU) begin
            ma_dout = {{16{1'b0}}, ma_mem_rdata[ex_mem_offset*B_WIDTH*2+:B_WIDTH*2]};
        end
        else begin
            ma_dout = ma_mem_rdata;
        end
    end

    always_ff @(posedge clk) begin
        if (ma_ready) begin
            for (integer i = 0; i < NUM_COL; i = i + 1) begin
                if (ex_mem_we[i]) begin
                    mem_block[ex_mem_addr][i*B_WIDTH+:B_WIDTH] <=
                        ex_mem_wdata[i*B_WIDTH+:B_WIDTH];
                end
            end
            ma_mem_rdata <= mem_block[ex_mem_addr];
        end
    end

endmodule : rip_memory

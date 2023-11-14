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
    input rip_common::inst_t ma_inst,
    input wire [rip_common::DATA_WIDTH-1:0] ex_addr,
    input wire [rip_common::DATA_WIDTH-1:0] ma_addr,
    input wire [rip_common::DATA_WIDTH-1:0] ex_din,
    output wire [rip_common::DATA_WIDTH-1:0] ma_dout
);
    import rip_common::*;

    (* ram_style = "block" *)
    reg [rip_common::DATA_WIDTH-1:0] mem_block[1<<rip_common::ADDR_WIDTH];

    logic [rip_common::ADDR_WIDTH-1:0] if_mem_addr;

    logic [rip_common::ADDR_WIDTH-1:0] ex_mem_addr;
    logic [1:0] ex_mem_offset;
    logic [1:0] ma_mem_offset;
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
        ma_mem_offset = ma_addr[1:0];

        for (integer i = 0; i < NUM_COL; i = i + 1) begin
            ex_mem_we[i] = ma_ready & ((ex_inst.SB && ex_mem_offset == i[1:0]) |
                                       (ex_inst.SH && ex_mem_offset[1] == i[1]) | ex_inst.SW);
        end

        if (ex_inst.SB) begin
            ex_mem_wdata = {24'd0, ex_din[7:0]} << (ex_mem_offset * B_WIDTH);
        end
        else if (ex_inst.SH) begin
            ex_mem_wdata = {16'd0, ex_din[15:0]} << (ex_mem_offset * B_WIDTH);
        end
        else begin
            ex_mem_wdata = ex_din;
        end

        if (ma_inst.LB) begin
            case (ma_mem_offset)
                2'b00: ma_dout = {{24{ma_mem_rdata[7]}}, ma_mem_rdata[7:0]};
                2'b01: ma_dout = {{24{ma_mem_rdata[15]}}, ma_mem_rdata[15:8]};
                2'b10: ma_dout = {{24{ma_mem_rdata[23]}}, ma_mem_rdata[23:16]};
                2'b11: ma_dout = {{24{ma_mem_rdata[31]}}, ma_mem_rdata[31:24]};
            endcase
        end
        else if (ma_inst.LH) begin
            casez (ma_mem_offset)
                2'b00: ma_dout = {{16{ma_mem_rdata[15]}}, ma_mem_rdata[15:0]};
                2'b01: ma_dout = {{16{ma_mem_rdata[23]}}, ma_mem_rdata[23:8]};
                2'b1?: ma_dout = {{16{ma_mem_rdata[31]}}, ma_mem_rdata[31:16]};
            endcase
        end
        else if (ma_inst.LBU) begin
            case (ma_mem_offset)
                2'b00: ma_dout = {24'b0, ma_mem_rdata[7:0]};
                2'b01: ma_dout = {24'b0, ma_mem_rdata[15:8]};
                2'b10: ma_dout = {24'b0, ma_mem_rdata[23:16]};
                2'b11: ma_dout = {24'b0, ma_mem_rdata[31:24]};
            endcase
        end
        else if (ma_inst.LHU) begin
            casez (ma_mem_offset)
                2'b00: ma_dout = {16'b0, ma_mem_rdata[15:0]};
                2'b01: ma_dout = {16'b0, ma_mem_rdata[23:8]};
                2'b1?: ma_dout = {16'b0, ma_mem_rdata[31:16]};
            endcase
        end
        else if (ma_inst.LW) begin
            ma_dout = ma_mem_rdata;
        end
        else begin
            ma_dout = 32'hFFFFFFFF;
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

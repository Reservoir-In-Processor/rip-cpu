/*
 * Module `rip_memory_access`
 *
 * Byte addressing memory system top module.
 */

`default_nettype none
`timescale 1ns / 1ps

module rip_memory_access
    import rip_const::*;
    import rip_type::*;
#(
    parameter int DATA_WIDTH = 32,
    parameter int NUM_COL = DATA_WIDTH / 8
) (
    input wire clk,

    output logic [3:0] we_1,
    output wire re_1,
    output wire re_2,
    output wire [31:0] addr_1,
    output wire [31:0] addr_2,
    output wire [31:0] din_1,
    input wire [31:0] dout_1,
    input wire [31:0] dout_2,

    input wire if_ready,
    input wire [DATA_WIDTH-1:0] pc,
    output logic [DATA_WIDTH-1:0] if_dout,

    input wire ma_ready,
    input inst_t ex_inst,
    input inst_t ma_inst,
    input wire [DATA_WIDTH-1:0] ex_addr,
    input wire [DATA_WIDTH-1:0] ma_addr,
    input wire [DATA_WIDTH-1:0] ex_din,
    output wire [DATA_WIDTH-1:0] ma_dout
);
    logic [1:0] ex_mem_offset;
    logic [1:0] ma_mem_offset;

    // instruction fetch
    assign re_2 = if_ready;
    assign addr_2 = {2'b0, pc[31:2]};
    assign if_dout = dout_2;

    // memory access
    assign re_1 = ma_ready & (ex_inst.LB | ex_inst.LH | ex_inst.LBU | ex_inst.LHU | ex_inst.LW);
    assign addr_1 = {2'b0, ex_addr[31:2]};
    always_comb begin
        ex_mem_offset = ex_addr[1:0];
        ma_mem_offset = ma_addr[1:0];

        for (integer i = 0; i < NUM_COL; i = i + 1) begin
            we_1[i] = ma_ready & ((ex_inst.SB && ex_mem_offset == i[1:0]) |
                                  (ex_inst.SH && ex_mem_offset[1] == i[1]) | ex_inst.SW);
        end

        if (ex_inst.SB) begin
            din_1 = {24'd0, ex_din[7:0]} << (ex_mem_offset * B_WIDTH);
        end
        else if (ex_inst.SH) begin
            din_1 = {16'd0, ex_din[15:0]} << (ex_mem_offset * B_WIDTH);
        end
        else begin
            din_1 = ex_din;
        end

        if (ma_inst.LB) begin
            case (ma_mem_offset)
                2'b00:   ma_dout = {{24{dout_1[7]}}, dout_1[7:0]};
                2'b01:   ma_dout = {{24{dout_1[15]}}, dout_1[15:8]};
                2'b10:   ma_dout = {{24{dout_1[23]}}, dout_1[23:16]};
                2'b11:   ma_dout = {{24{dout_1[31]}}, dout_1[31:24]};
                default: ma_dout = 32'hFFFFFFFF;
            endcase
        end
        else if (ma_inst.LH) begin
            casez (ma_mem_offset)
                2'b00:   ma_dout = {{16{dout_1[15]}}, dout_1[15:0]};
                2'b01:   ma_dout = {{16{dout_1[23]}}, dout_1[23:8]};
                2'b1?:   ma_dout = {{16{dout_1[31]}}, dout_1[31:16]};
                default: ma_dout = 32'hFFFFFFFF;
            endcase
        end
        else if (ma_inst.LBU) begin
            case (ma_mem_offset)
                2'b00:   ma_dout = {24'b0, dout_1[7:0]};
                2'b01:   ma_dout = {24'b0, dout_1[15:8]};
                2'b10:   ma_dout = {24'b0, dout_1[23:16]};
                2'b11:   ma_dout = {24'b0, dout_1[31:24]};
                default: ma_dout = 32'hFFFFFFFF;
            endcase
        end
        else if (ma_inst.LHU) begin
            casez (ma_mem_offset)
                2'b00:   ma_dout = {16'b0, dout_1[15:0]};
                2'b01:   ma_dout = {16'b0, dout_1[23:8]};
                2'b1?:   ma_dout = {16'b0, dout_1[31:16]};
                default: ma_dout = 32'hFFFFFFFF;
            endcase
        end
        else if (ma_inst.LW) begin
            ma_dout = dout_1;
        end
        else begin
            ma_dout = 32'hFFFFFFFF;
        end
    end
endmodule : rip_memory_access

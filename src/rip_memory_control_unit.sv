`default_nettype none
`timescale 1ns / 1ps

`include "rip_common.sv"

// Module: rip_memory_control_unit
// Description: byte addressing memory system top module.
module rip_memory_control_unit #(
    parameter DATA_WIDTH = 32, // data port width
    parameter ADDR_WIDTH = 32
) (
    input wire clk,
    input wire rstn,
    // input rip_common::inst_t instruction,
    input wire [3:0] we_1,
    input wire re_1,
    input wire re_2,
    input wire [ADDR_WIDTH-1:0] addr_1,
    input wire [ADDR_WIDTH-1:0] addr_2,
    input wire [DATA_WIDTH-1:0] din_1,
    output logic [DATA_WIDTH-1:0] dout_1,
    output logic [DATA_WIDTH-1:0] dout_2,
    output wire busy_1,
    output wire busy_2
);
    import rip_common::*;

    (* ram_style = "block" *)
    reg [rip_common::DATA_WIDTH-1:0] mem_block[1<<rip_common::ADDR_WIDTH];

    initial begin
`ifdef VERILATOR
        $readmemh("../../hex/testcase.hex", mem_block);
`else
        $readmemh("../../hex/fib.hex", mem_block);
`endif  // VERILATOR
    end

    logic [31:0] addr_1_buf;
    logic [31:0] addr_2_buf;

    logic [2:0] busy_1_cnt;
    logic [2:0] busy_2_cnt;
    localparam bit [2:0] BUSY_1_CNT_MAX = 3;
    localparam bit [2:0] BUSY_2_CNT_MAX = 3;

    assign busy_1 = busy_1_cnt != 0;
    assign busy_2 = busy_2_cnt != 0;

    always_ff @(posedge clk) begin
        for (integer i = 0; i < 4; i = i + 1) begin
            if (we_1[i]) begin
                mem_block[addr_1][i*8 +: 8] <= din_1[i*8 +: 8];
            end
        end

        if (!rstn) begin
            busy_1_cnt <= 0;
            busy_2_cnt <= 0;
        end
        else begin
            if (re_1 & !busy_1) begin
                addr_1_buf <= addr_1;
                busy_1_cnt <= 3'd1;
            end
            else if (busy_1 & busy_1_cnt < BUSY_1_CNT_MAX) begin
                busy_1_cnt <= busy_1_cnt + 1;
            end
            else if (busy_1_cnt == BUSY_1_CNT_MAX) begin
                dout_1 <= mem_block[addr_1_buf];
                busy_1_cnt <= 0;
            end

            if (re_2 & !busy_2) begin
                addr_2_buf <= addr_2;
                busy_2_cnt <= 3'd1;
            end
            else if (busy_2 && busy_2_cnt < BUSY_2_CNT_MAX) begin
                busy_2_cnt <= busy_2_cnt + 1;
            end
            else if (busy_2_cnt == BUSY_2_CNT_MAX) begin
                dout_2 <= mem_block[addr_2_buf];
                busy_2_cnt <= 0;
            end
        end
    end
endmodule

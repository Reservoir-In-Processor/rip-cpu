`default_nettype none
`timescale 1ns / 1ps

module rip_regfile
    import rip_config::*;
(
    input wire rst_n,
    input wire clk,

    input wire de_ready,
    input wire [4:0] ma_rd_num,
    input wire wen,
    input wire [31:0] wdata,

    input wire [4:0] if_rs1_num,
    input wire [4:0] if_rs2_num,
    output reg [31:0] rs1,
    output reg [31:0] rs2
);
    reg [31:0] regfile[32];

    // initialize and write
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < 32; i = i + 1) begin
                // sp; for riscv-tests
                if (i == 2) begin
                    regfile[i] <= SP_ADDR;
                end
                else begin
                    regfile[i] <= 0;
                end
            end
        end
        else begin
            for (int i = 1; i < 32; i = i + 1) begin
                if (wen && ma_rd_num == i[4:0]) begin
                    regfile[i] <= wdata;
                end
            end
        end
    end

    // read
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rs1 <= 0;
            rs2 <= 0;
        end
        else if (de_ready) begin
            rs1 <= wen && (ma_rd_num == if_rs1_num) ? wdata : regfile[if_rs1_num];
            rs2 <= wen && (ma_rd_num == if_rs2_num) ? wdata : regfile[if_rs2_num];
        end
    end
endmodule: rip_regfile

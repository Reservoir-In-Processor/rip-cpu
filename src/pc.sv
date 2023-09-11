`default_nettype none
`timescale 1ns / 1ps

module riscoffee_pc (
    input RST_N,
    input CLK,

    input JUMP_ENABLE,
    input [31:0] JUMP_OFFSET,
    output reg [31:0] PC
);
    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            PC <= 0;
        end else begin
            if (JUMP_ENABLE) begin
                PC <= PC + JUMP_OFFSET;
            end else begin
                PC <= PC + 4;
            end
        end
    end
endmodule

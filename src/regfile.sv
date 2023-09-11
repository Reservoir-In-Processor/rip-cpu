`default_nettype none
`timescale 1ns / 1ps

module riscoffee_regfile (
    input RST_N,
    input CLK,

    input [4:0] MA_RD_NUM,
    input WEN,
    input [31:0] WDATA,

    input [4:0] IF_RS1_NUM,
    input [4:0] IF_RS2_NUM,
    output reg [31:0] RS1,
    output reg [31:0] RS2
);
    reg [31:0] regfile[31:0];

    // initialize and write
    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            for (int i = 0; i < 32; i = i + 1) begin
                regfile[i] <= 0;
            end
        end else begin
            for (int i = 1; i < 32; i = i + 1) begin
                if (WEN && MA_RD_NUM == i[4:0]) begin
                    regfile[i] <= WDATA;
                end
            end
        end
    end

    // read
    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            RS1 <= 0;
            RS2 <= 0;
        end else begin
            RS1 <= WEN && (MA_RD_NUM == IF_RS1_NUM) ? WDATA : regfile[IF_RS1_NUM];
            RS2 <= WEN && (MA_RD_NUM == IF_RS2_NUM) ? WDATA : regfile[IF_RS2_NUM];
        end
    end
endmodule

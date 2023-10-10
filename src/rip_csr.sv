`default_nettype none
`timescale 1ns / 1ps

module rip_csr (
    input rst_n,
    input clk,

    input [11:0] ma_csr_num,
    input ma_wen,
    input [31:0] ma_csr_din,

    input [11:0] if_csr_num,
    output reg [31:0] de_csr_dout
);
    reg [31:0] csrfile[1<<12];

    // initialize and write
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // todo: initialize correctly
            for (int i = 0; i < (1 << 12); i = i + 1) begin
                csrfile[i] = 0;
            end
        end
        else if (ma_wen) begin
            csrfile[ma_csr_num] <= ma_csr_din;
        end
    end

    // read
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            de_csr_dout <= 0;
        end
        else begin
            de_csr_dout <= ma_wen && (ma_csr_num == if_csr_num) ? ma_csr_din : csrfile[if_csr_num];
        end
    end
endmodule

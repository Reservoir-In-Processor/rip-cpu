`default_nettype none
`timescale 1ns / 1ps

module rip_csr (
    input rst_n,
    input clk,

    input write,
    input set,
    input clear,
    input [11:0] csr_addr,
    input [31:0] csr_din,
    output reg [31:0] csr_dout
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
        else if (write) begin
            csrfile[csr_addr] <= csr_din;
        end
        else if (set) begin
            csrfile[csr_addr] <= csrfile[csr_addr] | csr_din;
        end
        else if (clear) begin
            csrfile[csr_addr] <= csrfile[csr_addr] & ~csr_din;
        end
    end

    // read
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            csr_dout <= 0;
        end
        else begin
            csr_dout <= csrfile[csr_addr];
        end
    end
endmodule

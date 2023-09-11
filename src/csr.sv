`default_nettype none
`timescale 1ns / 1ps

module riscoffee_csr (
    input RST_N,
    input CLK,

    input WRITE,
    input SET,
    input CLEAR,
    input [11:0] CSR_ADDR,
    input [31:0] CSR_DATA_IN,
    output reg [31:0] CSR_DATA_OUT
);
    reg [31:0] csrfile[(1<<12)-1:0];
    integer i;

    // initialize and write
    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            // todo: initialize correctly
            for (i = 0; i < (1 << 12); i++) begin
                csrfile[i] = 0;
            end
        end else if (WRITE) begin
            csrfile[CSR_ADDR] <= CSR_DATA_IN;
        end else if (SET) begin
            csrfile[CSR_ADDR] <= csrfile[CSR_ADDR] | CSR_DATA_IN;
        end else if (CLEAR) begin
            csrfile[CSR_ADDR] <= csrfile[CSR_ADDR] & ~CSR_DATA_IN;
        end
    end

    // read
    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            CSR_DATA_OUT <= 0;
        end else begin
            CSR_DATA_OUT <= csrfile[CSR_ADDR];
        end
    end
endmodule

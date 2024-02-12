`default_nettype none
`timescale 1ns / 1ps

//
// Synchronous FIFO implementation
//

module rip_fifo_sync #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 8
) (
    input wire clk,
    input wire rst,
    input wire w_en,
    input wire r_en,
    input wire [DATA_WIDTH-1:0] w_data,
    output logic [DATA_WIDTH-1:0] r_data,
    output logic w_full,
    output logic r_empty
);

    localparam DEPTH = 2 ** ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] sfifo [DEPTH-1:0];

    typedef logic [ADDR_WIDTH:0] addr_t; // +1 MSB for overflow checking

    addr_t w_addr;
    addr_t r_addr;

    always_ff @(posedge clk) begin
        if (rst) begin
            w_addr <= '0;
            r_addr <= '0;
        end else begin
            if (w_en && !w_full) begin
                sfifo[w_addr[ADDR_WIDTH-1:0]] <= w_data;
                w_addr <= w_addr + 1'b1;
            end
            if (r_en && !r_empty) begin
                r_addr <= r_addr + 1'b1;
            end
        end
    end

    assign r_data = sfifo[r_addr[ADDR_WIDTH-1:0]];

    // status
    assign w_full = (w_addr[ADDR_WIDTH-1:0] == r_addr[ADDR_WIDTH-1:0])
                    && (w_addr[ADDR_WIDTH] != r_addr[ADDR_WIDTH]);
    assign r_empty = (w_addr == r_addr);

endmodule

`default_nettype wire

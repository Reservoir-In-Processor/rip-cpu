`default_nettype none
`timescale 1ns / 1ps

//
// Asynchronous FIFO implementation
//

module rip_fifo_async #(
    parameter int DATA_WIDTH = 128,
    parameter int ADDR_WIDTH = 8
) (
    input wire w_clk,
    input wire r_clk,
    input wire w_rst,
    input wire r_rst,
    input wire w_en,
    input wire r_en,
    input wire [DATA_WIDTH-1:0] w_data,
    output logic [DATA_WIDTH-1:0] r_data,
    output logic w_full,
    output logic r_empty
);

    localparam DEPTH = 2 ** ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] afifo [DEPTH-1:0];

    typedef logic [ADDR_WIDTH:0] addr_t; // +1 MSB for overflow checking

    // use gray code and double FF synchronizer to cope with metastability
    //   w_addr --(convert)-> w_addr_gray
    //          --(pass to r_clk)-> w_addr_gray_r_1 --> w_addr_gray_r_2
    //          --(restore)-> w_addr_restored
    //   r_addr --(convert)-> r_addr_gray
    //          --(pass to w_clk)-> r_addr_gray_w_1 --> r_addr_gray_w_2
    //          --(restore)-> r_addr_restored
    addr_t w_addr;
    addr_t r_addr;
    addr_t w_addr_gray;
    addr_t r_addr_gray;
    addr_t w_addr_gray_r_1; // driven by r_clk (passed to r_clk domain)
    addr_t r_addr_gray_w_1; // driven by w_clk (passed to w_clk domain)
    addr_t w_addr_gray_r_2; // driven by r_clk
    addr_t r_addr_gray_w_2; // driven by w_clk
    addr_t w_addr_restored;
    addr_t r_addr_restored;

    // w_clk domain
    always_ff @(posedge w_clk) begin
        if (w_rst) begin
            w_addr <= '0;
            r_addr_gray_w_1 <= '0;
            r_addr_gray_w_2 <= '0;
        end else begin
            if (w_en && !w_full) begin
                afifo[w_addr[ADDR_WIDTH-1:0]] <= w_data;
                w_addr <= w_addr + 1'b1;
            end
            r_addr_gray_w_1 <= r_addr_gray;
            r_addr_gray_w_2 <= r_addr_gray_w_1;
        end
    end

    // convert from binary to gray code using XOR
    assign w_addr_gray = w_addr ^ {1'b0, w_addr[ADDR_WIDTH:1]};
    assign r_addr_gray = r_addr ^ {1'b0, r_addr[ADDR_WIDTH:1]};

    // restore binary from gray code
    generate
        for (genvar i = 0; i <= ADDR_WIDTH; i = i + 1) begin : GEN_RESTORE
            assign w_addr_restored[i] = ^w_addr_gray_r_2[ADDR_WIDTH:i];
            assign r_addr_restored[i] = ^r_addr_gray_w_2[ADDR_WIDTH:i];
        end
    endgenerate

    // r_clk domain
    always_ff @(posedge r_clk) begin
        if (r_rst) begin
            r_addr <= '0;
            w_addr_gray_r_1 <= '0;
            w_addr_gray_r_2 <= '0;
        end else begin
            if (r_en && !r_empty) begin
                r_addr <= r_addr + 1'b1;
            end
            w_addr_gray_r_1 <= w_addr_gray;
            w_addr_gray_r_2 <= w_addr_gray_r_1;
        end
    end

    assign r_data = afifo[r_addr[ADDR_WIDTH-1:0]];

    // status
    assign w_full = (w_addr[ADDR_WIDTH-1:0] == r_addr_restored[ADDR_WIDTH-1:0])
                    && (w_addr[ADDR_WIDTH] != r_addr_restored[ADDR_WIDTH]);
    assign r_empty = (w_addr_restored == r_addr);

endmodule

`default_nettype wire
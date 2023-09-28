`default_nettype none
`timescale 1ns / 1ps

// Module: rip_memory
// Description: byte addressing memory system top module.
module rip_memory #(
    parameter NUM_COL = 4,
    parameter COL_WIDTH = 8,
    parameter ADDR_WIDTH = 20,
    parameter DATA_WIDTH = NUM_COL * COL_WIDTH  // data port width
) (
    input wire clk,
    input wire rst_n,

    input inst ma_inst,
    input wire ma_en,
    input wire [DATA_WIDTH-1:0] ma_addr,
    input wire [DATA_WIDTH-1:0] ma_din,
    output wire [DATA_WIDTH-1:0] ma_dout,

    input wire if_en,
    input wire [DATA_WIDTH-1:0] pc,
    output wire [DATA_WIDTH-1:0] inst_code
);
    import rip_const::*;

    integer i;
    reg [DATA_WIDTH-1:0] mem_block[(1<<ADDR_WIDTH)-1:0];

    initial begin
        $readmemh("ram.hex", mem_block);
    end

    // instruction fetch
    always @(posedge clkB) begin
        if (if_en) begin
            doutB <= ram_block[addrB];
        end
    end

    // memory access
    always @(posedge clk) begin
        if (ma_en) begin
            for (i = 0; i < NUM_COL; i = i + 1) begin
                if (weA[i]) begin
                    ram_block[addrA][i*COL_WIDTH+:COL_WIDTH] <= dinA[i*COL_WIDTH+:COL_WIDTH];
                end
            end
            doutA <= ram_block[addrA];
        end
    end


endmodule

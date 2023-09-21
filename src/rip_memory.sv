`default_nettype none
`timescale 1ns / 1ps

// Module: rip_memory
// Description: byte addressing memory system top module.
module rip_memory #(
    parameter DATA_WIDTH = 32, // data port width
    parameter ADDR_WIDTH = 32
) (
    input wire clk,
    input wire rstn,
    input inst instruction,
    input wire we,
    input wire re_1,
    input wire re_2,
    input wire [ADDR_WIDTH-1:0] addr_1,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout_1,
    output wire [DATA_WIDTH-1:0] dout_2,
    output wire busy
);
    import rip_const::*;

    // TO BE IMPLEMENTED

endmodule

`default_nettype wire
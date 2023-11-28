`default_nettype none
`timescale 1ns / 1ps

// Module: rip_memory_management_unit
// Description: byte addressing memory system top module.
module rip_memory_management_unit
    import rip_const::*;
#(
    parameter DATA_WIDTH = 32, // data port width
    parameter ADDR_WIDTH = 32
) (
    input wire clk,
    input wire rstn,
    input wire [DATA_WIDTH/B_WIDTH-1:0] we_1,
    input wire re_1,
    input wire re_2,
    input wire [ADDR_WIDTH-1:0] addr_1,
    input wire [ADDR_WIDTH-1:0] addr_2,
    input wire [DATA_WIDTH-1:0] din_1,
    output logic [DATA_WIDTH-1:0] dout_1,
    output logic [DATA_WIDTH-1:0] dout_2,
    output logic busy_1,
    output logic busy_2
);

    // TO BE IMPLEMENTED

endmodule

`default_nettype wire

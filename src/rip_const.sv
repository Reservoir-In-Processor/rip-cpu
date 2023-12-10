`default_nettype none
`timescale 1ns / 1ps

`ifndef RIP_CONST
`define RIP_CONST

// define constant (not supposed to be changed) values
package rip_const;

    localparam int B_WIDTH = 8;  // byte width
    localparam int H_WIDTH = 16;  // half word width
    localparam int W_WIDTH = 32;  // word width
    localparam int D_WIDTH = 64;  // double word width

endpackage : rip_const

`endif  // RIP_CONST

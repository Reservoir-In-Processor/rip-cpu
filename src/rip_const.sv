`ifndef RIP_CONST
`define RIP_CONST

`default_nettype none
`timescale 1ns / 1ps

// define constant (not supposed to be changed) values
package rip_const;

    localparam B_WIDTH = 8;  // byte width
    localparam H_WIDTH = 16; // half word width
    localparam W_WIDTH = 32; // word width
    localparam D_WIDTH = 64; // double word width
    
endpackage

`endif
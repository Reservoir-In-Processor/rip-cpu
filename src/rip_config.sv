`default_nettype none
`timescale 1ns / 1ps

`ifndef RIP_CONFIG
`define RIP_CONFIG

package rip_config;

    localparam bit [31:0] SP_ADDR = 32'h1 << 25;

    localparam bit [11:0] MTVEC = 12'h305;
    localparam bit [11:0] MEPC = 12'h341;
    localparam bit [11:0] MCAUSE = 12'h342;
    localparam bit [11:0] CYCLE = 12'hC00;

    localparam int CAUSE_ILLEGAL_INST = 2;
    localparam int CAUSE_ECALL = 11;

endpackage : rip_config

`endif  // RIP_CONFIG

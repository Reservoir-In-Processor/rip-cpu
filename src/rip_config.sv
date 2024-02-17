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
    localparam bit [11:0] BPTP = 12'hFC0;
    localparam bit [11:0] BPTN = 12'hFC1;
    localparam bit [11:0] BPFP = 12'hFC2;
    localparam bit [11:0] BPFN = 12'hFC3;

    localparam int CAUSE_ILLEGAL_INST = 2;
    localparam int CAUSE_ECALL = 11;

    /*
    branch predictor configurations
    */

    /* define one of below models */
    // `define BIMODAL
    `define GSHARE

    /// which part of PC to use for the table index
    localparam int BP_PC_LSB = 3;
    localparam int BP_PC_MSB = 12;

    /// ignored for BIMODAL and GSHARE
    localparam int BP_HISTORY_LEN = 10;

endpackage : rip_config

`endif  // RIP_CONFIG

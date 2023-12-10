// define constant (not supposed to be changed) values
localparam int B_WIDTH = 8;  // byte width
localparam int H_WIDTH = 16; // half word width
localparam int W_WIDTH = 32; // word width
localparam int D_WIDTH = 64; // double word width

localparam int ADDR_WIDTH = 22;          // address width
localparam int DATA_WIDTH = W_WIDTH;     // data width
localparam int NUM_COL = DATA_WIDTH / 8; // number of columns in memory

localparam bit [31:0] START_ADDR = 32'h0;
localparam bit [31:0] SP_ADDR = 32'1 << 25;

localparam bit [11:0] MTVEC = 12'h305;
localparam bit [11:0] MEPC = 12'h341;
localparam bit [11:0] MCAUSE = 12'h342;

localparam int CAUSE_ILLEGAL_INST = 2;
localparam int CAUSE_ECALL = 11;

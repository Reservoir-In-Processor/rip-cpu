
`default_nettype none
`timescale 1ns / 1ps

module riscoffee_ram #(
    parameter NUM_COL = 4,
    parameter COL_WIDTH = 8,
    parameter ADDR_WIDTH = 20,
    parameter DATA_WIDTH = NUM_COL * COL_WIDTH
) (
    input CLK,
    input WEN,

    input inst INST,

    input [31:0] PC,
    input [31:0] ADDR,
    input [DATA_WIDTH-1:0] DIN,
    output logic [DATA_WIDTH-1:0] DOUT
);
    reg [DATA_WIDTH-1:0] ram_block[(1<<ADDR_WIDTH)-1:0];

    logic [ADDR_WIDTH-1:0] ram_addr;
    logic [1:0] ram_offset;
    logic [NUM_COL-1:0] we;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;

    // initialize
    initial begin
        $readmemh("../hex/ram.hex", ram_block);
    end

    // input
    always_comb begin
        if (INST.LB | INST.LH | INST.LW | INST.LBU | INST.LHU | INST.SB | INST.SH | INST.SW) begin
            ram_addr = ADDR[ADDR_WIDTH+1:2];
        end else begin
            ram_addr = PC[ADDR_WIDTH+1:2];
        end
        ram_offset = ADDR[1:0];

        for (int i = 0; i < NUM_COL; i = i + 1) begin
            we[i] = (INST.SB && ram_offset == i[1:0]) | (INST.SH && ram_offset[1] == i[1]) | INST.SW;
        end

        if (INST.SB) begin
            wdata = {24'd0, DIN[7:0]} << (ram_offset * COL_WIDTH);
        end else if (INST.SH) begin
            wdata = {16'd0, DIN[15:0]} << (ram_offset * COL_WIDTH * 2);
        end else begin
            wdata = DIN;
        end
    end

    // ram
    always @(posedge CLK) begin
        for (int i = 0; i < NUM_COL; i = i + 1) begin
            if (we[i]) begin
                ram_block[ram_addr][i*COL_WIDTH+:COL_WIDTH] <= wdata[i*COL_WIDTH+:COL_WIDTH];
            end
        end
        rdata <= ram_block[ram_addr];
    end

    // output
    always_comb begin
        if (INST.LB) begin
            DOUT = {{24{rdata[ram_offset*COL_WIDTH+7]}}, rdata[ram_offset*COL_WIDTH+:COL_WIDTH]};
        end else if (INST.LH) begin
            DOUT = {{16{rdata[ram_offset*COL_WIDTH+15]}}, rdata[ram_offset*COL_WIDTH*2+:COL_WIDTH*2]};
        end else if (INST.LBU) begin
            DOUT = {24'b0, rdata[ram_offset*COL_WIDTH+:COL_WIDTH]};
        end else if (INST.LHU) begin
            DOUT = {16'b0, rdata[ram_offset*COL_WIDTH*2+:COL_WIDTH*2]};
        end else begin
            DOUT = rdata;
        end
    end
endmodule

`default_nettype none
`timescale 1ns / 1ps

// Module: rip_pseudo_core_mmu
// Description: pseudo core with MMU for testing on a board.
module rip_pseudo_core_mmu #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32, // data port width
    parameter int AXI_ID_WIDTH = 4,
    parameter int AXI_DATA_WIDTH = 32
) (
    input wire clk,
    input wire rstn,
    input wire [ADDR_WIDTH-1:0] mem_head,
    output wire [1:0] busy,
    rip_axi_interface.master M_AXI
);
    import rip_const::*;

    // MMU control signals
    logic [DATA_WIDTH/B_WIDTH-1:0] we_1;
    logic re_1;
    logic re_2;
    logic [ADDR_WIDTH-1:0] addr_1;
    logic [ADDR_WIDTH-1:0] addr_2;
    logic [DATA_WIDTH-1:0] din_1;
    logic [DATA_WIDTH-1:0] dout_1;
    logic [DATA_WIDTH-1:0] dout_2;
    logic busy_1;
    logic busy_2;

    rip_memory_management_unit #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) mmu (
        .*
    );

    enum logic [5:0] {
        SLEEP,
        INIT,
        READ,
        READWAIT,
        WRITE,
        WRITEWAIT
    } state;

    assign busy = state == SLEEP ? 'b00 :
                    state == READ  || state == READWAIT  ? 'b10 :
                    state == WRITE || state == WRITEWAIT ? 'b11 :
                    'b01;

    logic [ADDR_WIDTH-1:0] mem_offset;
    logic [ADDR_WIDTH-1:0] cnt;
    logic [ADDR_WIDTH-1:0] addr;
    logic [AXI_DATA_WIDTH-1:0] data;
    assign addr = mem_offset | (cnt << 2);
    assign data = dout_1;
    localparam int data_len = 256;

    always_ff @(posedge clk) begin
        if (~rstn) begin
            state <= SLEEP;
            mem_offset <= '0;
            cnt <= '0;
            we_1 <= '0;
            re_1 <= '0;
            re_2 <= '0;
            addr_1 <= '0;
            addr_2 <= '0;
            din_1 <= '0;
        end else begin
            case (state)
                SLEEP: begin
                    if (mem_head != '1) begin
                        mem_offset <= mem_head;
                        state <= INIT;
                        cnt <= '0;
                        we_1 <= '0;
                        re_1 <= '0;
                        re_2 <= '0;
                    end
                end
                INIT: begin
                    if (mem_offset == mem_head) begin
                        state <= READ;
                        addr_1 <= addr;
                        re_1 <= '1;
                    end else begin
                        state <= SLEEP;
                    end
                end
                READ: begin
                    if (~busy_1) begin
                        state <= READWAIT;
                        re_1 <= '0;
                    end
                end
                READWAIT: begin
                    if (~busy_1) begin
                        state <= WRITE;
                        we_1 <= '1;
                        din_1 <= data;
                    end
                end
                WRITE: begin
                    if (~busy_1) begin
                        state <= WRITEWAIT;
                        cnt <= cnt + 1'b1;
                        we_1 <= '0;
                    end
                end
                WRITEWAIT: begin
                    if (~busy_1) begin
                        if (cnt < data_len) begin
                            state <= READ;
                            addr_1 <= addr;
                            re_1 <= '1;
                        end else begin
                            state <= SLEEP;
                        end
                    end
                end
            endcase
        end
    end

endmodule

`default_nettype wire

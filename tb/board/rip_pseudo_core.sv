`default_nettype none
`timescale 1ns / 1ps

// Module: rip_pseudo_core
// Description: pseudo core for testing on a board.
module rip_pseudo_core #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32, // data port width
    parameter AXI_ID_WIDTH = 4,
    parameter AXI_DATA_WIDTH = 32
) (
    input wire clk,
    input wire rstn,
    input wire [ADDR_WIDTH-1:0] mem_head,
    output wire [1:0] busy,
    rip_axi_interface.master M_AXI
);
    import rip_const::*;

    // AXI master control signals
    logic wready;
    logic [ADDR_WIDTH-1:0] waddr;
    logic [AXI_DATA_WIDTH-1:0] wdata;
    logic [AXI_DATA_WIDTH/B_WIDTH-1:0] wstrb;
    logic wvalid;
    logic wdone;
    logic rready;
    logic [ADDR_WIDTH-1:0] raddr;
    logic rvalid;
    logic [AXI_DATA_WIDTH-1:0] rdata;
    logic rdone;

    rip_axi_master #(
        .ID_WIDTH(AXI_ID_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(AXI_DATA_WIDTH),
        .BURST_LEN(1)
    ) AXIM (
        .clk(clk),
        .rstn(rstn),
        .wready(wready),
        .waddr(waddr),
        .wdata(wdata),
        .wstrb(wstrb),
        .wvalid(wvalid),
        .wdone(wdone),
        .rready(rready),
        .raddr(raddr),
        .rvalid(rvalid),
        .rdata(rdata),
        .rdone(rdone),
        .M_AXI(M_AXI)
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
    assign data = rdata;
    localparam data_len = 256;

    always_ff @(posedge clk) begin
        if (~rstn) begin
            state <= SLEEP;
            mem_offset <= '0;
            cnt <= '0;
            waddr <= '0;
            wdata <= '0;
            wstrb <= '0;
            wvalid <= '0;
            raddr <= '0;
            rvalid <= '0;
        end else begin
            case (state)
                SLEEP: begin
                    if (mem_head != '1) begin
                        mem_offset <= mem_head;
                        state <= INIT;
                        cnt <= '0;
                        wvalid <= '0;
                        rvalid <= '0;
                    end
                end
                INIT: begin
                    if (mem_offset == mem_head) begin
                        state <= READ;
                        raddr <= addr;
                        rvalid <= '1;
                    end else begin
                        state <= SLEEP;
                    end
                end
                READ: begin
                    if (rready && rvalid) begin
                        state <= READWAIT;
                        rvalid <= '0;
                    end
                end
                READWAIT: begin
                    if (rdone) begin
                        state <= WRITE;
                        waddr <= addr;
                        wdata <= data;
                        wstrb <= '1;
                        wvalid <= '1;
                    end
                end
                WRITE: begin
                    if (wready && wvalid) begin
                        state <= WRITEWAIT;
                        cnt <= cnt + 1'b1;
                        wvalid <= '0;
                    end
                end
                WRITEWAIT: begin
                    if (wdone) begin
                        if (cnt < data_len) begin
                            state <= READ;
                            raddr <= addr;
                            rvalid <= '1;
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

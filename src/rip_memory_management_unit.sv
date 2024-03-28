`default_nettype none
`timescale 1ns / 1ps

// Module: rip_memory_management_unit
// Description: byte addressing memory system top module.
module rip_memory_management_unit
    import rip_const::*;
#(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32, // data port width
    // cache configuration
    // `TAG_WIDTH + INDEX_WIDTH + log(LINE_SIZE) == ADDR_WIDTH`
    parameter int TAG_WIDTH = 15,
    parameter int INDEX_WIDTH = 15,
    parameter int LINE_SIZE = 4, // bytes per cache line (>= 4)
    parameter int WAY_NUM = 1,
    // AXI configuration
    parameter int AXI_ID_WIDTH = 4,
    parameter int AXI_DATA_WIDTH = 32
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
    output logic busy_2,
    rip_axi_interface.master M_AXI
);
    import rip_axi_interface_const::*;

    // AXI master control signals
    logic wready;
    logic [ADDR_WIDTH-1:0] waddr;
    logic [LINE_SIZE*B_WIDTH-1:0] wdata;
    logic [LINE_SIZE-1:0] wstrb;
    logic wvalid;
    logic wdone;
    logic rready;
    logic [ADDR_WIDTH-1:0] raddr;
    logic rvalid;
    logic [LINE_SIZE*B_WIDTH-1:0] rdata;
    logic rdone;

    localparam int BURST_LEN = LINE_SIZE / (AXI_DATA_WIDTH / B_WIDTH);
    rip_axi_master #(
        .ID_WIDTH(AXI_ID_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(AXI_DATA_WIDTH),
        .BURST_LEN(BURST_LEN)
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

    // TO BE IMPLEMENTED

    // temporary implementation (without cache)
    // re_1 has priority over re_2

    logic busy_1_w;
    logic busy_1_r;
    assign busy_1 = busy_1_w || busy_1_r;
    // wait xready
    logic wait_1_w;
    logic wait_1_r;
    logic wait_1_r_2; // wait channel 2 read completion
    logic [ADDR_WIDTH-1:0] raddr_1;
    logic wait_2;
    logic wait_2_1; // wait channel 1 read completion
    logic [ADDR_WIDTH-1:0] raddr_2;

    always_ff @(posedge clk) begin
        if (~rstn) begin
            // AXI master control singnals
            waddr <= '0;
            wdata <= '0;
            wstrb <= '0;
            wvalid <= '0;
            raddr <= '0;
            rvalid <= '0;
            // internal states and buffers
            busy_1_w <= '0;
            busy_1_r <= '0;
            wait_1_w <= '0;
            wait_1_r <= '0;
            wait_1_r_2 <= '0;
            raddr_1 <= '0;
            wait_2 <= '0;
            wait_2_1 <= '0;
            raddr_2 <= '0;
            // module outputs
            dout_1 <= '0;
            dout_2 <= '0;
            busy_2 <= '0;
        end else begin
            // channel 1
            if (busy_1) begin
                if (busy_1_w) begin
                    if (wait_1_w) begin
                        if (wready) begin
                            wvalid <= '0;
                            wait_1_w <= '0;
                        end
                    end else begin
                        wvalid <= '0;
                        if (wdone) begin
                            busy_1_w <= '0;
                        end
                    end
                end else if (busy_1_r) begin
                    if (wait_1_r_2) begin
                        if (busy_2) begin
                            wait_1_r_2 <= '1; // keep waiting
                        end else begin
                            raddr <= raddr_1;
                            rvalid <= '1;
                            wait_1_r_2 <= '0;
                            if (~rready) begin
                                wait_1_r <= '1;
                            end
                        end
                    end else if (wait_1_r) begin
                        if (rready) begin
                            rvalid <= '0;
                            wait_1_r <= '0;
                        end
                    end else begin
                        rvalid <= '0;
                        if (rdone) begin
                            dout_1 <= rdata;
                            busy_1_r <= '0;
                        end
                    end
                end
            end else if (we_1) begin
                waddr <= addr_1;
                wdata <= din_1;
                wstrb <= we_1;
                wvalid <= '1;
                busy_1_w <= '1;
                if (~wready) begin
                    wait_1_w <= '1;
                end
            end else if (re_1) begin
                if (busy_2 && ~wait_2_1) begin
                    // only when re_2 is not waiting re_1 (to avoid deadlock)
                    raddr_1 <= addr_1;
                    busy_1_r <= '1;
                    wait_1_r_2 <= '1;
                end else begin
                    raddr <= addr_1;
                    rvalid <= '1;
                    busy_1_r <= '1;
                    if (~rready) begin
                        wait_1_r <= '1;
                    end
                end
            end
            // channel 2
            if (busy_2) begin
                if (wait_2_1) begin
                    if (re_1 || busy_1_r) begin
                        wait_2_1 <= '1; // keep waiting
                    end else begin
                        raddr <= raddr_2;
                        rvalid <= '1;
                        wait_2_1 <= '0;
                        if (~rready) begin
                            wait_2 <= '1;
                        end
                    end
                end else if (wait_2) begin
                    if (rready) begin
                        rvalid <= '0;
                        wait_2 <= '0;
                    end
                end else begin
                    rvalid <= '0;
                    if (rdone) begin
                        dout_2 <= rdata;
                        busy_2 <= '0;
                    end
                end
            end else if (re_2) begin
                if (re_1 || busy_1_r) begin
                    raddr_2 <= addr_2;
                    busy_2 <= '1;
                    wait_2_1 <= '1;
                end else begin
                    raddr <= addr_2;
                    rvalid <= '1;
                    busy_2 <= '1;
                    if (~rready) begin
                        wait_2 <= '1;
                    end
                end
            end
        end
    end

endmodule

`default_nettype wire

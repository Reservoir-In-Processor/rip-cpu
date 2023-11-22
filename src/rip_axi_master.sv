`default_nettype none
`timescale 1ns / 1ps

//
// AXI4 master implementation
// - uses handshake signals for state control
// - assumes the burst length to be fixed
// - omits some AXI4-only signals
// - does not check transaction responses
// - does not support strobes
// - does not support outstandings
//

module rip_axi_master #(
    parameter ID_WIDTH = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32, // Burst size
    parameter BURST_LEN = 1
) (
    input wire clk,
    input wire rstn,
    // Write access
    output logic wready,
    input wire [ADDR_WIDTH-1:0] waddr,
    input wire [DATA_WIDTH*BURST_LEN-1:0] wdata,
    input wire wvalid,
    output logic wdone,
    // Read access
    output logic rready,
    input wire [ADDR_WIDTH-1:0] raddr,
    input wire rvalid,
    output logic [DATA_WIDTH*BURST_LEN-1:0] rdata,
    output logic rdone,
    // AXI interface
    rip_axi_interface.master AXIM
);
    import rip_const::*;
    import rip_axi_interface_const::*;

    // not crossing a 4KB address boundary is ensured by the parent module
    localparam AXLEN = BURST_LEN - 1;
    localparam AXSIZE = $clog2(DATA_WIDTH / B_WIDTH) - 1;

    logic [$clog2(BURST_LEN)-1:0] wcnt;
    logic [$clog2(BURST_LEN)-1:0] rcnt;

    // Write channels
    always_ff @(posedge clk) begin
        if (~rstn) begin
            // Write address channel signals
            AXIM.AWID <= '0;
            AXIM.AWADDR <= '0;
            AXIM.AWLEN <= '0;
            AXIM.AWSIZE <= '0;
            AXIM.AWBURST <= '0;
            AXIM.AWLOCK <= '0;
            AXIM.AWCACHE <= '0;
            AXIM.AWPROT <= '0;
            AXIM.AWVALID <= '0;
            // Write data channel signals
            AXIM.WID <= '0;
            AXIM.WDATA <= '0;
            AXIM.WSTRB <= '0;
            AXIM.WLAST <= '0;
            AXIM.WVALID <= '0;
            wready <= '0;
            wdone <= '0;
            wcnt <= '0;
            // Write response channel signals
            AXIM.BREADY <= '0;
        end else begin
            if (wready && wvalid) begin : WriteInit
                // Write address channel signals
                AXIM.AWID <= AXIM.AWID + 1'b1;
                AXIM.AWADDR <= waddr;
                AXIM.AWLEN <= AXLEN;
                AXIM.AWSIZE <= AXSIZE;
                AXIM.AWBURST <= AXI_BURST.INCR;
                AXIM.AWVALID <= 1'b1;
                // Write data channel signals
                AXIM.WID <= AXIM.WID + 1'b1;
                AXIM.WDATA <= wdata[0 +: DATA_WIDTH];
                // AXIM.WSTRB <= '1;
                AXIM.WLAST <= (AXLEN == 0) ? 1'b1 : '0;
                AXIM.WVALID <= 1'b1;
                wready <= '0;
                wdone <= '0;
                wcnt <= 1'b1;
                // Write response channel signals
                AXIM.BREADY <= '0;
            end else if (AXIM.WVALID) begin : WritingData
                if (AXIM.AWREADY && AXIM.AWVALID) begin
                    AXIM.AWVALID <= '0;
                end
                if (AXIM.WREADY) begin // wrote one beat
                    if (AXIM.WLAST) begin
                        AXIM.WLAST <= '0;
                        AXIM.WVALID <= '0;
                        AXIM.BREADY <= 1'b1;
                    end else begin
                        AXIM.WDATA <= wdata[DATA_WIDTH*wcnt +: DATA_WIDTH];
                        wcnt <= wcnt + 1'b1;
                        if (wcnt == AXLEN) begin
                            AXIM.WLAST <= 1'b1;
                        end
                    end
                end
            end else if (AXIM.BREADY) begin : WaitWriteResp
                if (AXIM.BVALID) begin
                    AXIM.BREADY <= '0;
                    wready <= 1'b1;
                    wdone <= 1'b1;
                end
            end else begin
                wready <= 1'b1;
                wdone <= '0;
            end
        end
    end

    // Read channels
    always_ff @(posedge clk) begin
        if (~rstn) begin
            // Read address channel signals
            AXIM.ARID <= '0;
            AXIM.ARADDR <= '0;
            AXIM.ARLEN <= '0;
            AXIM.ARSIZE <= '0;
            AXIM.ARBURST <= '0;
            AXIM.ARLOCK <= '0;
            AXIM.ARCACHE <= '0;
            AXIM.ARPROT <= '0;
            AXIM.ARVALID <= '0;
            // Read data channel signals
            AXIM.RREADY <= '0;
            rready <= '0;
            rdata <= '0;
            rdone <= '0;
            rcnt <= '0;
        end else begin
            if (rready && rvalid) begin : ReadInit
                // Read address channel signals
                AXIM.ARID <= AXIM.ARID + 1'b1;
                AXIM.ARADDR <= raddr;
                AXIM.ARLEN <= AXLEN;
                AXIM.ARSIZE <= AXSIZE;
                AXIM.ARBURST <= AXI_BURST.INCR;
                AXIM.ARVALID <= 1'b1;
                // Read data channel signals
                AXIM.RREADY <= 1'b1;
                rready <= '0;
                rdata <= '0;
                rdone <= '0;
                rcnt <= '0;
            end else if (AXIM.ARVALID) begin : WaitAddrRead
                if (AXIM.ARREADY) begin
                    AXIM.ARVALID <= '0;
                end
            end else if (AXIM.RREADY) begin : ReadingData
                // RVALID is asserted AFTER both ARVALID and ARREADY are asserted
                if (AXIM.RVALID) begin // read one beat
                    rdata <= rdata | (AXIM.RDATA << (DATA_WIDTH * rcnt));
                    rcnt <= rcnt + 1'b1;
                    if (AXIM.RLAST) begin
                        AXIM.RREADY <= '0;
                        rready <= 1'b1;
                        rdone <= 1'b1;
                    end
                end
            end else begin
                rready <= 1'b1;
                rdone <= '0;
            end
        end
    end

endmodule

`default_nettype wire

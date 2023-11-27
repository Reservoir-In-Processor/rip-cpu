`default_nettype none
`timescale 1ns / 1ps

//
// AXI4 master implementation
// - supports independent write/read access
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
    rip_axi_interface.master M_AXI
);
    import rip_const::*;
    import rip_axi_interface_const::*;

    // not crossing a 4KB address boundary is ensured by the parent module
    localparam AXLEN = BURST_LEN - 1;
    localparam AXSIZE = $clog2(DATA_WIDTH / B_WIDTH);

    localparam BURST_CNT_WIDTH = (BURST_LEN > 1) ? $clog2(BURST_LEN) : 1;
    logic [BURST_CNT_WIDTH-1:0] wcnt;
    logic [BURST_CNT_WIDTH-1:0] rcnt;

    // Write channels
    always_ff @(posedge clk) begin
        if (~rstn) begin
            // Write address channel signals
            M_AXI.AWID <= '0;
            M_AXI.AWADDR <= '0;
            M_AXI.AWLEN <= '0;
            M_AXI.AWSIZE <= '0;
            M_AXI.AWBURST <= '0;
            M_AXI.AWLOCK <= '0;
            M_AXI.AWCACHE <= '0;
            M_AXI.AWPROT <= '0;
            M_AXI.AWQOS <= '0;
            M_AXI.AWREGION <= '0;
            M_AXI.AWVALID <= '0;
            // Write data channel signals
            M_AXI.WID <= '0;
            M_AXI.WDATA <= '0;
            M_AXI.WSTRB <= '0;
            M_AXI.WLAST <= '0;
            M_AXI.WVALID <= '0;
            wready <= '0;
            wdone <= '0;
            wcnt <= '0;
            // Write response channel signals
            M_AXI.BREADY <= '0;
        end else begin
            if (wready && wvalid) begin : WriteInit
                // Write address channel signals
                M_AXI.AWID <= M_AXI.AWID + 1'b1;
                M_AXI.AWADDR <= waddr;
                M_AXI.AWLEN <= AXLEN;
                M_AXI.AWSIZE <= AXSIZE;
                M_AXI.AWBURST <= INCR;
                M_AXI.AWVALID <= 1'b1;
                // Write data channel signals
                M_AXI.WID <= M_AXI.WID + 1'b1;
                M_AXI.WDATA <= wdata[0 +: DATA_WIDTH];
                M_AXI.WSTRB <= '1;
                M_AXI.WLAST <= (AXLEN == 0) ? 1'b1 : '0;
                M_AXI.WVALID <= 1'b1;
                wready <= '0;
                wdone <= '0;
                wcnt <= 1'b1;
                // Write response channel signals
                M_AXI.BREADY <= '0;
            end else if (M_AXI.WVALID) begin : WritingData
                if (M_AXI.AWREADY && M_AXI.AWVALID) begin
                    M_AXI.AWVALID <= '0;
                end
                if (M_AXI.WREADY) begin // wrote one beat
                    if (M_AXI.WLAST) begin
                        M_AXI.WLAST <= '0;
                        M_AXI.WVALID <= '0;
                        M_AXI.BREADY <= 1'b1;
                    end else begin
                        M_AXI.WDATA <= wdata[DATA_WIDTH*wcnt +: DATA_WIDTH];
                        wcnt <= wcnt + 1'b1;
                        if (wcnt == AXLEN) begin
                            M_AXI.WLAST <= 1'b1;
                        end
                    end
                end
            end else if (M_AXI.BREADY) begin : WaitWriteResp
                if (M_AXI.BVALID) begin
                    M_AXI.BREADY <= '0;
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
            M_AXI.ARID <= '0;
            M_AXI.ARADDR <= '0;
            M_AXI.ARLEN <= '0;
            M_AXI.ARSIZE <= '0;
            M_AXI.ARBURST <= '0;
            M_AXI.ARLOCK <= '0;
            M_AXI.ARCACHE <= '0;
            M_AXI.ARPROT <= '0;
            M_AXI.ARQOS <= '0;
            M_AXI.ARREGION <= '0;
            M_AXI.ARVALID <= '0;
            // Read data channel signals
            M_AXI.RREADY <= '0;
            rready <= '0;
            rdata <= '0;
            rdone <= '0;
            rcnt <= '0;
        end else begin
            if (rready && rvalid) begin : ReadInit
                // Read address channel signals
                M_AXI.ARID <= M_AXI.ARID + 1'b1;
                M_AXI.ARADDR <= raddr;
                M_AXI.ARLEN <= AXLEN;
                M_AXI.ARSIZE <= AXSIZE;
                M_AXI.ARBURST <= INCR;
                M_AXI.ARVALID <= 1'b1;
                // Read data channel signals
                M_AXI.RREADY <= 1'b1;
                rready <= '0;
                rdata <= '0;
                rdone <= '0;
                rcnt <= '0;
            end else if (M_AXI.ARVALID) begin : WaitAddrRead
                if (M_AXI.ARREADY) begin
                    M_AXI.ARVALID <= '0;
                end
            end else if (M_AXI.RREADY) begin : ReadingData
                // RVALID is asserted AFTER both ARVALID and ARREADY are asserted
                if (M_AXI.RVALID) begin // read one beat
                    rdata <= rdata | (M_AXI.RDATA << (DATA_WIDTH * rcnt));
                    rcnt <= rcnt + 1'b1;
                    if (M_AXI.RLAST) begin
                        M_AXI.RREADY <= '0;
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

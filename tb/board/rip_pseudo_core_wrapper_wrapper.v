module rip_pseudo_core_wrapper_wrapper #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32, // data port width
    parameter AXI_ID_WIDTH = 4,
    parameter AXI_DATA_WIDTH = 32
) (
    input wire clk,
    input wire rstn,
    input wire [ADDR_WIDTH-1:0] mem_head,
    output wire [1:0] busy,
    // Write address channel signals
    output wire [AXI_ID_WIDTH-1:0] AWID,
    output wire [ADDR_WIDTH-1:0] AWADDR,
    output wire [7:0] AWLEN,
    output wire [2:0] AWSIZE,
    output wire [1:0] AWBURST,
    output wire AWLOCK,
    output wire [3:0] AWCACHE,
    output wire [2:0] AWPROT,
    output wire [3:0] AWQOS,
    output wire [3:0] AWREGION,
    output wire AWVALID,
    input wire AWREADY,
    // Write data channel signals
    output wire [AXI_ID_WIDTH-1:0] WID, // for debug
    output wire [AXI_DATA_WIDTH-1:0] WDATA,
    output wire [AXI_DATA_WIDTH/8-1:0] WSTRB,
    output wire WLAST,
    output wire WVALID,
    input wire WREADY,
    // Write response channel signals
    input wire [AXI_ID_WIDTH-1:0] BID,
    input wire [1:0] BRESP,
    input wire BVALID,
    output wire BREADY,
    // Read address channel signals
    output wire [AXI_ID_WIDTH-1:0] ARID,
    output wire [ADDR_WIDTH-1:0] ARADDR,
    output wire [7:0] ARLEN,
    output wire [2:0] ARSIZE,
    output wire [1:0] ARBURST,
    output wire ARLOCK,
    output wire [3:0] ARCACHE,
    output wire [2:0] ARPROT,
    output wire [3:0] ARQOS,
    output wire [3:0] ARREGION,
    output wire ARVALID,
    input wire ARREADY,
    // Read data channel signals
    input wire [AXI_ID_WIDTH-1:0] RID,
    input wire [AXI_DATA_WIDTH-1:0] RDATA,
    input wire [1:0] RRESP,
    input wire RLAST,
    input wire RVALID,
    output wire RREADY
);
    rip_pseudo_core_wrapper #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) zynq_pl_wrapper (
        .clk(clk),
        .rstn(rstn),
        .mem_head(mem_head),
        .busy(busy),
        .AWID(AWID),
        .AWADDR(AWADDR),
        .AWLEN(AWLEN),
        .AWSIZE(AWSIZE),
        .AWBURST(AWBURST),
        .AWLOCK(AWLOCK),
        .AWCACHE(AWCACHE),
        .AWPROT(AWPROT),
        .AWQOS(AWQOS),
        .AWREGION(AWREGION),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WID(WID),
        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WLAST(WLAST),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BID(BID),
        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .ARID(ARID),
        .ARADDR(ARADDR),
        .ARLEN(ARLEN),
        .ARSIZE(ARSIZE),
        .ARBURST(ARBURST),
        .ARLOCK(ARLOCK),
        .ARCACHE(ARCACHE),
        .ARPROT(ARPROT),
        .ARQOS(ARQOS),
        .ARREGION(ARREGION),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RID(RID),
        .RDATA(RDATA),
        .RRESP(RRESP),
        .RLAST(RLAST),
        .RVALID(RVALID),
        .RREADY(RREADY)
    );
endmodule
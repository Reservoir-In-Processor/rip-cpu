module rip_pseudo_core_wrapper #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32, // data port width
    parameter int AXI_ID_WIDTH = 4,
    parameter int AXI_DATA_WIDTH = 32
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
    rip_axi_interface #(
        .ID_WIDTH(AXI_ID_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi_if ();

    // rip_pseudo_core #(
    rip_pseudo_core_mmu #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) zynq_pl (
        .clk(clk),
        .rstn(rstn),
        .mem_head(mem_head),
        .busy(busy),
        .M_AXI(axi_if)
    );

    assign AWID = axi_if.AWID;
    assign AWADDR = axi_if.AWADDR;
    assign AWLEN = axi_if.AWLEN;
    assign AWSIZE = axi_if.AWSIZE;
    assign AWBURST = axi_if.AWBURST;
    assign AWLOCK = axi_if.AWLOCK;
    assign AWCACHE = axi_if.AWCACHE;
    assign AWPROT = axi_if.AWPROT;
    assign AWQOS = axi_if.AWQOS;
    assign AWREGION = axi_if.AWREGION;
    assign AWVALID = axi_if.AWVALID;
    assign axi_if.AWREADY = AWREADY;
    assign WID = WID;
    assign WDATA = axi_if.WDATA;
    assign WSTRB = axi_if.WSTRB;
    assign WLAST = axi_if.WLAST;
    assign WVALID = axi_if.WVALID;
    assign axi_if.WREADY = WREADY;
    assign axi_if.BID = BID;
    assign axi_if.BRESP = BRESP;
    assign axi_if.BVALID = BVALID;
    assign BREADY = axi_if.BREADY;
    assign ARID = axi_if.ARID;
    assign ARADDR = axi_if.ARADDR;
    assign ARLEN = axi_if.ARLEN;
    assign ARSIZE = axi_if.ARSIZE;
    assign ARBURST = axi_if.ARBURST;
    assign ARLOCK = axi_if.ARLOCK;
    assign ARCACHE = axi_if.ARCACHE;
    assign ARPROT = axi_if.ARPROT;
    assign ARQOS = axi_if.ARQOS;
    assign ARREGION = axi_if.ARREGION;
    assign ARVALID = axi_if.ARVALID;
    assign axi_if.ARREADY = ARREADY;
    assign axi_if.RID = RID;
    assign axi_if.RDATA = RDATA;
    assign axi_if.RRESP = RRESP;
    assign axi_if.RLAST = RLAST;
    assign axi_if.RVALID = RVALID;
    assign RREADY = axi_if.RREADY;
endmodule

interface rip_axi_interface #(
    parameter ID_WIDTH = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
);
    // Write address channel signals
    logic [ID_WIDTH-1:0] AWID;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0] AWLEN;
    logic [2:0] AWSIZE;
    logic [1:0] AWBURST;
    logic [1:0] AWLOCK;
    logic [3:0] AWCACHE;
    logic [2:0] AWPROT;
    logic AWVALID;
    logic AWREADY;
    // Write data channel signals
    logic [ID_WIDTH-1:0] WID;
    logic [DATA_WIDTH-1:0] WDATA;
    logic [DATA_WIDTH/8-1:0] WSTRB;
    logic WLAST;
    logic WVALID;
    logic WREADY;
    // Write response channel signals
    logic [ID_WIDTH-1:0] BID;
    logic BRESP;
    logic BVALID;
    logic BREADY;
    // Read address channel signals
    logic [ID_WIDTH-1:0] ARID;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0] ARLEN;
    logic [2:0] ARSIZE;
    logic [1:0] ARBURST;
    logic [1:0] ARLOCK;
    logic [3:0] ARCACHE;
    logic [2:0] ARPROT;
    logic ARVALID;
    logic ARREADY;
    // Read data channel signals
    logic [ID_WIDTH-1:0] RID;
    logic [DATA_WIDTH-1:0] RDATA;
    logic RRESP;
    logic RLAST;
    logic RVALID;
    logic RREADY;

    modport master (
        // Write address channel signals
        output AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWCACHE, AWPROT, AWVALID,
        input AWREADY,
        // Write data channel signals
        output WID, WDATA, WSTRB, WLAST, WVALID,
        input WREADY,
        // Write response channel signals
        input BID, BRESP, BVALID,
        output BREADY,
        // Read address channel signals
        output ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARCACHE, ARPROT, ARVALID,
        input ARREADY,
        // Read data channel signals
        input RID, RDATA, RRESP, RLAST, RVALID,
        output RREADY
    );

    modport slave (
        // Write address channel signals
        input AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWCACHE, AWPROT, AWVALID,
        output AWREADY,
        // Write data channel signals
        input WID, WDATA, WSTRB, WLAST, WVALID,
        output WREADY,
        // Write response channel signals
        output BID, BRESP, BVALID,
        input BREADY,
        // Read address channel signals
        input ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARCACHE, ARPROT, ARVALID,
        output ARREADY,
        // Read data channel signals
        output RID, RDATA, RRESP, RLAST, RVALID,
        input RREADY
    );

endinterface //rip_axi_interface

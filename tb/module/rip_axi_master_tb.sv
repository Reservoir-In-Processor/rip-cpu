`timescale 1ns / 1ps

module rip_axi_master_tb #(
    parameter int ID_WIDTH = 4,
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32, // Burst size
    parameter int BURST_LEN = 2
) (
);
    import rip_const::*;
    import rip_axi_interface_const::*;
    import axi_vip_pkg::*;
    import axi_vip_0_pkg::*; // component name retrived from IP configuration window

    logic SYS_CLK = '0;
    localparam int SYS_CLK_PERIOD = 10;
    initial forever #(SYS_CLK_PERIOD/2) SYS_CLK = ~SYS_CLK;

    logic SYS_RSTN = '0;

    logic wready;
    logic [ADDR_WIDTH-1:0] waddr;
    logic [DATA_WIDTH*BURST_LEN-1:0] wdata;
    logic [DATA_WIDTH*BURST_LEN/B_WIDTH-1:0] wstrb;
    logic wvalid;
    logic wdone;
    logic rready;
    logic [ADDR_WIDTH-1:0] raddr;
    logic rvalid;
    logic [DATA_WIDTH*BURST_LEN-1:0] rdata;
    logic rdone;
    task automatic reset_logics();
        wready <= '0;
        waddr <= '0;
        wdata <= '0;
        wstrb <= '0;
        wvalid <= '0;
        rready <= '0;
        raddr <= '0;
        rvalid <= '0;
    endtask // reset_logics

    rip_axi_interface #(
        .ID_WIDTH(ID_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) axi_if ();

    rip_axi_master #(
        .ID_WIDTH(ID_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BURST_LEN(BURST_LEN)
    ) AXIM (
        .clk(SYS_CLK),
        .rstn(SYS_RSTN),
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
        .M_AXI(axi_if.master)
    );

    axi_vip_0 axi_vip_0_slave (
        .aclk(SYS_CLK),                      // input wire aclk
        .aresetn(SYS_RSTN),                // input wire aresetn
        .s_axi_awid(axi_if.AWID),          // input wire [3 : 0] s_axi_awid
        .s_axi_awaddr(axi_if.AWADDR),      // input wire [31 : 0] s_axi_awaddr
        .s_axi_awlen(axi_if.AWLEN),        // input wire [7 : 0] s_axi_awlen
        .s_axi_awsize(axi_if.AWSIZE),      // input wire [2 : 0] s_axi_awsize
        .s_axi_awburst(axi_if.AWBURST),    // input wire [1 : 0] s_axi_awburst
        .s_axi_awlock(axi_if.AWLOCK),      // input wire [0 : 0] s_axi_awlock
        .s_axi_awcache(axi_if.AWCACHE),    // input wire [3 : 0] s_axi_awcache
        .s_axi_awprot(axi_if.AWPROT),      // input wire [2 : 0] s_axi_awprot
        .s_axi_awregion(axi_if.AWREGION),  // input wire [3 : 0] s_axi_awregion
        .s_axi_awqos(axi_if.AWQOS),        // input wire [3 : 0] s_axi_awqos
        .s_axi_awvalid(axi_if.AWVALID),    // input wire s_axi_awvalid
        .s_axi_awready(axi_if.AWREADY),    // output wire s_axi_awready
        .s_axi_wdata(axi_if.WDATA),        // input wire [31 : 0] s_axi_wdata
        .s_axi_wstrb(axi_if.WSTRB),        // input wire [3 : 0] s_axi_wstrb
        .s_axi_wlast(axi_if.WLAST),        // input wire s_axi_wlast
        .s_axi_wvalid(axi_if.WVALID),      // input wire s_axi_wvalid
        .s_axi_wready(axi_if.WREADY),      // output wire s_axi_wready
        .s_axi_bid(axi_if.BID),            // output wire [3 : 0] s_axi_bid
        .s_axi_bresp(axi_if.BRESP),        // output wire [1 : 0] s_axi_bresp
        .s_axi_bvalid(axi_if.BVALID),      // output wire s_axi_bvalid
        .s_axi_bready(axi_if.BREADY),      // input wire s_axi_bready
        .s_axi_arid(axi_if.ARID),          // input wire [3 : 0] s_axi_arid
        .s_axi_araddr(axi_if.ARADDR),      // input wire [31 : 0] s_axi_araddr
        .s_axi_arlen(axi_if.ARLEN),        // input wire [7 : 0] s_axi_arlen
        .s_axi_arsize(axi_if.ARSIZE),      // input wire [2 : 0] s_axi_arsize
        .s_axi_arburst(axi_if.ARBURST),    // input wire [1 : 0] s_axi_arburst
        .s_axi_arlock(axi_if.ARLOCK),      // input wire [0 : 0] s_axi_arlock
        .s_axi_arcache(axi_if.ARCACHE),    // input wire [3 : 0] s_axi_arcache
        .s_axi_arprot(axi_if.ARPROT),      // input wire [2 : 0] s_axi_arprot
        .s_axi_arregion(axi_if.ARREGION),  // input wire [3 : 0] s_axi_arregion
        .s_axi_arqos(axi_if.ARQOS),        // input wire [3 : 0] s_axi_arqos
        .s_axi_arvalid(axi_if.ARVALID),    // input wire s_axi_arvalid
        .s_axi_arready(axi_if.ARREADY),    // output wire s_axi_arready
        .s_axi_rid(axi_if.RID),            // output wire [3 : 0] s_axi_rid
        .s_axi_rdata(axi_if.RDATA),        // output wire [31 : 0] s_axi_rdata
        .s_axi_rresp(axi_if.RRESP),        // output wire [1 : 0] s_axi_rresp
        .s_axi_rlast(axi_if.RLAST),        // output wire s_axi_rlast
        .s_axi_rvalid(axi_if.RVALID),      // output wire s_axi_rvalid
        .s_axi_rready(axi_if.RREADY)      // input wire s_axi_rready
    );

    axi_vip_0_slv_mem_t agent;

    task automatic write(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH*BURST_LEN-1:0] data,
        input logic [DATA_WIDTH*BURST_LEN/B_WIDTH-1:0] strb
    );
        while (~wready) begin
            @(posedge SYS_CLK);
        end
        $display("writing @ 0x%h... %6d[ns]", addr, $time);
        waddr <= addr;
        wdata <= data;
        wstrb <= strb;
        wvalid <= '1;
        @(posedge SYS_CLK);
        wvalid <= '0;
        while (~wdone) begin
            @(posedge SYS_CLK);
        end
        $display("        << wrote '0x%h' [%b] @ 0x%h %6d[ns]", data, strb, addr, $time);
    endtask

    task automatic read(
        input logic [ADDR_WIDTH-1:0] addr
    );
        while (~rready) begin
            @(posedge SYS_CLK);
        end
        $display("reading @ 0x%h... %6d[ns]", addr, $time);
        raddr <= addr;
        rvalid <= '1;
        @(posedge SYS_CLK);
        rvalid <= '0;
        while (~rdone) begin
            @(posedge SYS_CLK);
        end
        $display("        >> read  '0x%h' @ 0x%h %6d[ns]", rdata, addr, $time);
    endtask

    initial begin
        SYS_RSTN <= '0;
        reset_logics();
        repeat(100) @(posedge SYS_CLK);
        SYS_RSTN <= '1;
        // XilinxAXIVIP: Found at Path: rip_axi_master_tb.axi_vip_0_slave.inst
        agent = new("slave vip agent",  rip_axi_master_tb.axi_vip_0_slave.inst.IF);
        agent.start_slave();
        $display("[RIP] start simulation");
        repeat(100) @(posedge SYS_CLK);
        write('h10, 'h1234, '1);
        read('h10);
        write('h10, 'h1234567890abcdef, '1);
        write('h18, 'hcdef90ab56781234, '1);
        read('h10);
        read('h14);
        read('h18);
        read('h1c);
        write('h20, 'hcafecafecafecafe, '1);
        write('h28, 'hbeafbeafbeafbeaf, '1);
        read('h28);
        read('h20);
        read('h24);
        write('h20, 'hbeefbeefbeefbeef, 'b01100100);
        read('h20);
        read('h24);
        write('h30, 'hc0ffeeadd1c0ffee, '1);
        fork
            read('h30);
            write('h38, 'hfab1e55, '1);
        join
        read('h38);
        repeat(100) @(posedge SYS_CLK);
        $finish;
    end

endmodule

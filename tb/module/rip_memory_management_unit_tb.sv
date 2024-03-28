`timescale 1ns / 1ps

module rip_memory_management_unit_tb #(
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
);
    import rip_const::*;
    import rip_axi_interface_const::*;
    import axi_vip_pkg::*;
    import axi_vip_0_pkg::*; // component name retrived from IP configuration window

    logic SYS_CLK = '0;
    localparam int sys_clk_period = 10;
    initial forever #(sys_clk_period/2) SYS_CLK = ~SYS_CLK;

    logic SYS_RSTN = '0;

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
    task automatic reset_logics();
        we_1 <= '0;
        re_1 <= '0;
        re_2 <= '0;
        addr_1 <= '0;
        addr_2 <= '0;
        din_1 <= '0;
    endtask // reset_logics

    rip_axi_interface #(
        .ID_WIDTH(AXI_ID_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) axi_if ();

    rip_memory_management_unit #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .TAG_WIDTH(TAG_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH),
        .LINE_SIZE(LINE_SIZE),
        .WAY_NUM(WAY_NUM),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) MMU (
        .clk(SYS_CLK),
        .rstn(SYS_RSTN),
        .we_1(we_1),
        .re_1(re_1),
        .re_2(re_2),
        .addr_1(addr_1),
        .addr_2(addr_2),
        .din_1(din_1),
        .dout_1(dout_1),
        .dout_2(dout_2),
        .busy_1(busy_1),
        .busy_2(busy_2),
        .M_AXI(axi_if)
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

    int write_1_cnt_bgn = 0;
    int write_1_cnt_end = 0;
    int read_1_cnt_bgn = 0;
    int read_1_cnt_end = 0;
    int read_2_cnt_bgn = 0;
    int read_2_cnt_end = 0;

    task automatic write_1_dispatch(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH/B_WIDTH-1:0] we,
        input logic [DATA_WIDTH-1:0] data
    );
        $display("%6d[ns] we_1 #%2d <--- @ 0x%h 0x%h[%b]",
                $time,
                write_1_cnt_bgn++, addr, data, we);
        addr_1 <= addr;
        we_1 <= we;
        din_1 <= data;
    endtask

    task automatic write_1_wait();
        while (busy_1) begin
            @(posedge SYS_CLK);
        end
        we_1 <= '0;
    endtask

    task automatic write_1(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH/B_WIDTH-1:0] we,
        input logic [DATA_WIDTH-1:0] data
    );
        write_1_dispatch(addr, we, data);
        @(posedge SYS_CLK);
        write_1_wait();
    endtask

    always @(negedge MMU.busy_1_w) begin
        if (SYS_RSTN) begin
            $display("%6d[ns]       << wrote(1) #%2d",
                    $time,
                    write_1_cnt_end++);
        end
    end

    task automatic read_1_dispatch(
        input logic [ADDR_WIDTH-1:0] addr
    );
        $display("%6d[ns] re_1 #%2d ---> @ 0x%h",
                $time,
                read_1_cnt_bgn++, addr);
        addr_1 <= addr;
        re_1 <= '1;
    endtask

    task automatic read_1_wait();
        while (busy_1) begin
            @(posedge SYS_CLK);
        end
        re_1 <= '0;
    endtask

    task automatic read_1(
        input logic [ADDR_WIDTH-1:0] addr
    );
        read_1_dispatch(addr);
        @(posedge SYS_CLK);
        read_1_wait();
    endtask

    always @(negedge MMU.busy_1_r) begin
        if (SYS_RSTN) begin
            $display("%6d[ns]       >> read(1)       #%2d 0x%h",
                    $time,
                    read_1_cnt_end++, dout_1);
        end
    end

    task automatic read_2_dispatch(
        input logic [ADDR_WIDTH-1:0] addr
    );
        $display("%6d[ns] re_2 #%2d ---> @ 0x%h",
                $time,
                read_2_cnt_bgn++, addr);
        addr_2 <= addr;
        re_2 <= '1;
    endtask

    task automatic read_2_wait();
        while (busy_2) begin
            @(posedge SYS_CLK);
        end
        re_2 <= '0;
    endtask

    task automatic read_2(
        input logic [ADDR_WIDTH-1:0] addr
    );
        read_2_dispatch(addr);
        @(posedge SYS_CLK);
        read_2_wait();
    endtask

    always @(negedge busy_2) begin
        if (SYS_RSTN) begin
            $display("%6d[ns]       >> read(2)       #%2d 0x%h",
                    $time,
                    read_2_cnt_end++, dout_2);
        end
    end

    int unsigned data[13] = {
        'h01234567,
        'h89abcdef,
        'hcafecafe,
        'hbeefbeef,
        'hdecafe10,
        'hcdef89ab,
        'h45670123,
        'haaaaaaaa,
        'hbbbbbbbb,
        'hcccccccc,
        'hdddddddd,
        'heeeeeeee,
        'hffffffff
    };

    int cnt = 0;
    initial begin
        SYS_RSTN <= '0;
        reset_logics();
        repeat(100) @(posedge SYS_CLK);
        SYS_RSTN <= '1;
        agent = new("slave vip agent",  rip_memory_management_unit_tb.axi_vip_0_slave.inst.IF);
        agent.start_slave();
        $display("[RIP] start simulation");
        repeat(100) @(posedge SYS_CLK);

        $display("test channel 1");
        write_1('h4 * cnt, '1, data[cnt]);
        read_1('h4 * cnt);
        cnt++;
        write_1('h4 * cnt, '1, data[cnt]);
        read_1('h4 * cnt);
        cnt++;
        write_1('h4 * cnt, '1, data[cnt]);
        write_1('h4 * (cnt+1), '1, data[cnt+1]);
        read_1('h4 * cnt);
        read_1('h4 * (cnt+1));
        cnt++; cnt++;
        write_1('h4 * cnt, '1, data[cnt]);
        read_1('h4 * cnt);
        repeat(20) @(posedge SYS_CLK);

        $display("test channel 2");
        cnt++;
        write_1('h4 * cnt, '1, data[cnt]);
        read_2('h4 * cnt);
        repeat(20) @(posedge SYS_CLK);

        cnt++;
        write_1_dispatch('h4 * cnt, '1, data[cnt]);
        read_2_dispatch('h4 * (cnt-1));
        @(posedge SYS_CLK);
        fork
            write_1_wait();
            read_2_wait();
        join
        cnt++;
        write_1_dispatch('h4 * cnt, '1, data[cnt]);
        read_2_dispatch('h4 * (cnt-1));
        @(posedge SYS_CLK);
        fork
            write_1_wait();
            read_2_wait();
        join
        repeat(20) @(posedge SYS_CLK);

        cnt++;
        write_1('h4 * cnt, '1, data[cnt]);
        read_1('h4 * (cnt-2)); // (*1)
        read_2('h4 * (cnt-1)); // (*2)
        read_1('h4 * cnt); // test deadlock case
            // may wait *1, but must not wait *2 (which waits another re_1, i.e. *1)
        repeat(20) @(posedge SYS_CLK);

        cnt++;
        write_1('h4 * cnt, '1, data[cnt]);
        repeat(10) @(posedge SYS_CLK);

        read_1_dispatch('h4 * (cnt-1)); // copmpletes first
        read_2_dispatch('h4 * cnt); // (*3)
        @(posedge SYS_CLK);
        fork
            read_1_wait();
            read_2_wait();
        join
        cnt++;
        write_1('h4 * cnt, '1, data[cnt]);
        read_1('h4 * cnt); // test deadlock case
            // may wait *3 (ongoing AXI transaction, not waiting re_1)
        repeat(20) @(posedge SYS_CLK);

        cnt++;
        write_1('h4 * cnt, '1, data[cnt]);
        repeat(10) @(posedge SYS_CLK);

        read_2_dispatch('h4 * (cnt-1)); // (*4)
        @(posedge SYS_CLK);
        read_1_dispatch('h4 * cnt); // test deadlock case
            // may wait *4 (ongoing AXI transaction, not waiting re_1)
        re_2 <= '0;
        @(posedge SYS_CLK);
        fork
            read_2_wait();
            read_1_wait();
        join
        repeat(20) @(posedge SYS_CLK);

        $display("test strobes");
        cnt++;
        write_1('h4 * cnt, '1, data[cnt]);
        read_1('h4 * cnt);
        write_1('h4 * cnt, 'b1010, data[0]);
        read_1('h4 * cnt);
        repeat(100) @(posedge SYS_CLK);
        $finish;
    end

endmodule

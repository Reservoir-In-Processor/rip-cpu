`ifndef RIP_AXI_INTERFACE_CONST
`define RIP_AXI_INTERFACE_CONST

// constant values from the AXI protocol specification
package rip_axi_interface_const;

    enum {
        FIXED = 2'b00,
        INCR  = 2'b01,
        WRAP  = 2'b10
    } AXI_BURST;

    enum {
        OKAY   = 2'b00,
        EXOKAY = 2'b01,
        SLVERR = 2'b10,
        DECERR = 2'b11
    } AXI_RESP;

endpackage

`endif

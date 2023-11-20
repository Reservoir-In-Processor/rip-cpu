`default_nettype none
`timescale 1ns / 1ps

//
// branch predictor implementation
//

module rip_axi_master #(
    // Pattern History Table
    parameter PHT_LSB = 0,
    parameter PHT_MSB = 31,
    // Global History
    parameter GLOBAL_HISTORY_DEPTH = 10
) (
    input wire [31:0] pc,
    output logic pred,
    input wire actual
);

    // to be implemented
    assign pred = '1; // always taken

endmodule

`default_nettype wire

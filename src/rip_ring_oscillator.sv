`default_nettype none
`timescale 1ns / 1ps

// Module: rip_ring_oscillator
// Description: simple ring oscillator with odd number inverters
module rip_ring_oscillator #(
    parameter INVERTER_DELAY = 1,
    parameter RO_SIZE = 3 // # of NOT gates (odd, >=3)
) (
    input wire rstn,
    output logic ro
);

    (* ALLOW_COMBINATORIAL_LOOPS = "true", KEEP = "true", DONT_TOUCH = "yes" *)
    wire [RO_SIZE-1:0] nots;

    assign ro = nots[0];

    generate
        for (genvar i = 0; i < RO_SIZE; i++) begin
            if (i == 0) begin
                not #(INVERTER_DELAY) (nots[(i+1) % RO_SIZE], ~rstn ? '0 : nots[i]);
            end else begin
                not #(INVERTER_DELAY) (nots[(i+1) % RO_SIZE], nots[i]);
            end
        end
    endgenerate

endmodule

`default_nettype wire

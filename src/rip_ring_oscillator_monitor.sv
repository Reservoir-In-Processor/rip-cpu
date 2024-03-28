`default_nettype none
`timescale 1ns / 1ps

// Module: rip_ring_oscillator_monitor
// Description: returns if RO count delta2qaz3wesx increased from the previous sample cycle
module rip_ring_oscillator_monitor #(
    parameter int INVERTER_DELAY = 1,
    parameter int RO_SIZE = 3, // # of NOT gates (odd, >=3)
    parameter int RO_DATAWIDTH = 32,
    parameter int RO_SAMPLE_CYCLE = 100
) (
    input wire clk,
    input wire rstn,
    output logic sdelta // second delta (delta of delta)
);

    logic [$clog2(RO_SAMPLE_CYCLE):0] sample_cycle_cnt;

    logic [RO_DATAWIDTH-1:0] cnt;
    logic [RO_DATAWIDTH-1:0] cnt_prev;
    logic signed [RO_DATAWIDTH:0] cnt_delta;
    logic signed [RO_DATAWIDTH:0] cnt_delta_prev;

    assign cnt_delta = cnt - cnt_prev;

    logic ro;

    (* DONT_TOUCH = "yes" *)
    rip_ring_oscillator #(
        .INVERTER_DELAY(INVERTER_DELAY),
        .RO_SIZE(RO_SIZE)
    ) ro_inst (
        .rstn(rstn),
        .ro(ro)
    );

    always_ff @(posedge ro) begin
        if (~rstn) begin
            cnt <= '0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (~rstn) begin
            sample_cycle_cnt <= '0;
            cnt_prev <= '0;
            cnt_delta_prev <= '0;
            sdelta <= '0;
        end else begin
            if (sample_cycle_cnt == RO_SAMPLE_CYCLE) begin
                sample_cycle_cnt <= '0;
                cnt_prev <= cnt;
                cnt_delta_prev <= cnt_delta;
                sdelta <= (cnt_delta_prev <= cnt_delta);
            end else begin
                sample_cycle_cnt <= sample_cycle_cnt + 1'b1;
            end
        end
    end

endmodule

`default_nettype wire

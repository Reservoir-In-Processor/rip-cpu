`default_nettype none
`timescale 1ns / 1ps

//
// branch predictor implementation
// - Bimodal predictor
// - define 'GSHARE' to use as Gshare predictor
//

module rip_branch_predictor #(
    // Pattern History Table
    parameter PHT_LSB = 0,
    parameter PHT_MSB = 31
) (
    input wire clk,
    input wire rstn,
    input wire [31:0] pc,
    output logic pred,
    input wire update, // deasserted when stall
    input wire actual
);

    localparam PHT_DEPTH = PHT_MSB - PHT_LSB + 1;
    localparam PH_WIDTH = 2; // two bit saturating counter
    localparam GLOBAL_HISTORY_DEPTH = PHT_DEPTH;

    logic [PHT_DEPTH-1:0] previous_index;
    logic [PHT_DEPTH-1:0] current_index;
    logic [PHT_DEPTH-1:0] global_histroy;
    assign current_index = pc[PHT_MSB:PHT_LSB] ^ global_histroy;

    typedef enum logic [PH_WIDTH-1:0] {
        STRONGLY_UNTAKEN = 'b00,
        WEAKLY_UNTAKEN   = 'b01,
        WEAKLY_TAKEN     = 'b10,
        STRONGLY_TAKEN   = 'b11,
        NONE = 'x
    } two_bit_saturating_counter_t;

    two_bit_saturating_counter_t pred_counter_value;
    assign pred = pred_counter_value >= WEAKLY_TAKEN;

    two_bit_saturating_counter_t previous_counter_value;
    two_bit_saturating_counter_t update_counter_value;

    always_ff @(posedge clk) begin
        if (~rstn) begin
            global_histroy <= '0;
            previous_index <= '0;
            previous_counter_value <= NONE;
        end else begin
            if (update) begin
                `ifdef GSHARE
                    if (PHT_DEPTH == 1) begin
                        global_histroy <= actual;
                    end else begin
                        global_histroy <= {global_histroy[PHT_DEPTH-2:0], actual};
                    end
                `endif GSHARE
                previous_index <= current_index;
                previous_counter_value <= pred_counter_value;
            end else begin
                global_histroy <= global_histroy;
                previous_index <= previous_index;
                previous_counter_value <= previous_counter_value;
            end
        end
    end

    always_comb begin
        if (update) begin
            case (previous_counter_value)
                STRONGLY_UNTAKEN:
                    update_counter_value = actual ? WEAKLY_UNTAKEN : STRONGLY_UNTAKEN;
                WEAKLY_UNTAKEN:
                    update_counter_value = actual ? WEAKLY_TAKEN   : STRONGLY_UNTAKEN;
                WEAKLY_TAKEN:
                    update_counter_value = actual ? STRONGLY_TAKEN : WEAKLY_UNTAKEN;
                STRONGLY_TAKEN:
                    update_counter_value = actual ? STRONGLY_TAKEN : WEAKLY_TAKEN;
                default:
                    update_counter_value = NONE;
            endcase
        end else begin
            update_counter_value = update_counter_value;
        end
    end

    rip_2r1w_bram #(
        .DATA_WIDTH(PH_WIDTH),
        .ADDR_WIDTH(PHT_DEPTH)
    ) PHT (
        .clk(clk),
        .enable_1(rstn),
        .enable_2(rstn),
        .addr_1(previous_index),
        .addr_2(current_index),
        .we_1(update),
        .din_1(update_counter_value),
        // .dout_1(),
        .dout_2(pred_counter_value)
    );

endmodule

`default_nettype wire

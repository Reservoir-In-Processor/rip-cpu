`default_nettype none
`timescale 1ns / 1ps

//
// branch predictor implementation
// - Bimodal predictor
// - define 'GSHARE' to use as Gshare predictor
//

module rip_branch_predictor
    import rip_branch_predictor_const::*;
#(
    // Pattern History Table
    parameter PHT_LSB = 0,
    parameter PHT_MSB = 31
) (
    input wire clk,
    input wire rstn,
    input wire [31:0] pc,
    output logic [PHT_MSB-PHT_LSB:0] pred_index,
    output rip_bpw_t pred_weight,
    output logic pred,
    input wire update, // deasserted when stall
    input wire [PHT_MSB-PHT_LSB:0] update_index,
    input wire rip_bpw_t update_weight,
    input wire actual
);

    localparam PHT_DEPTH = PHT_MSB - PHT_LSB + 1;
    localparam PH_WIDTH = 2; // two bit saturating counter
    localparam GLOBAL_HISTORY_DEPTH = PHT_DEPTH;

    /* predict */
    logic [PHT_DEPTH-1:0] current_index;
    logic [PHT_DEPTH-1:0] global_histroy;
    assign current_index = pc[PHT_MSB:PHT_LSB] ^ global_histroy;

    assign pred = pred_weight >= WEAKLY_TAKEN;

    always_ff @(posedge clk) begin
        if (~rstn) begin
            pred_index <= '0;
            global_histroy <= '0;
        end else begin
            pred_index <= current_index;
            if (update) begin
                `ifdef GSHARE
                    if (PHT_DEPTH == 1) begin
                        global_histroy <= actual;
                    end else begin
                        global_histroy <= {global_histroy[PHT_DEPTH-2:0], actual};
                    end
                `endif // GSHARE
            end else begin
                global_histroy <= global_histroy;
            end
        end
    end

    /* update */
    rip_bpw_t update_counter_value;

    always_comb begin
        if (update) begin
            case (update_weight)
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

    /* table */
    rip_2r1w_bram #(
        .DATA_WIDTH(PH_WIDTH),
        .ADDR_WIDTH(PHT_DEPTH)
    ) PHT (
        .clk(clk),
        .enable_1(rstn),
        .enable_2(rstn),
        .addr_1(update_index),
        .addr_2(current_index),
        .we_1(update),
        .din_1(update_counter_value),
        // .dout_1(),
        .dout_2(pred_weight)
    );

endmodule

`default_nettype wire

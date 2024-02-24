`default_nettype none
`timescale 1ns / 1ps

//
// branch predictor implementation
// - Bimodal predictor
// - define 'GSHARE' to use as Gshare predictor
//

module rip_branch_predictor
    import rip_config::*;
    import rip_branch_predictor_const::*;
#(
) (
    input wire clk,
    input wire rstn,
    input wire [31:0] pc,
    output bp_index_t pred_index,
    output bp_weight_t pred_weight,
    output logic pred,
    input wire update, // deasserted when stall
    input wire bp_index_t update_index,
    input wire bp_weight_t update_weight,
    input wire actual
);

    /* predict */
    logic [HISTORY_LEN-1:0] global_histroy;
    logic [TABLE_DEPTH-1:0] current_index;
    weight_t current_weight;

    `ifdef PERCEPTRON
        assign current_index = pc[BP_PC_MSB:BP_PC_LSB];
        logic [WEIGHT_WIDTH-1:0] pred_y;
        always_comb begin
            pred_y = current_weight[WEIGHT_NUM-1];
            for (int i = 0; i < WEIGHT_NUM - 1; i++) begin
                if (global_histroy[i]) begin
                    pred_y += current_weight[i];
                end else begin
                    pred_y -= current_weight[i];
                end
            end
        end
        assign pred_weight.history = global_histroy;
        assign pred_weight.weights = current_weight;
        assign pred_weight.y = pred_y;
        assign pred = ~ pred_y[WEIGHT_WIDTH-1]; // sign (>= 0 ?)
    `else /* BIMODAL || GSHARE */
        assign current_index = pc[BP_PC_MSB:BP_PC_LSB] ^ global_histroy;
        assign pred_weight = bp_weight_t'(current_weight);
        assign pred = pred_weight >= WEAKLY_TAKEN;
    `endif

    logic [HISTORY_LEN-1:0] new_global_history;
    generate
        if (HISTORY_LEN == 1) begin
            assign new_global_history = actual;
        end else begin
            assign new_global_history = {global_histroy[HISTORY_LEN-2:0], actual};
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (~rstn) begin
            pred_index <= '0;
            global_histroy <= '0;
        end else begin
            pred_index <= current_index;
            if (update) begin
                `ifndef BIMODAL
                    global_histroy <= new_global_history;
                `endif
            end else begin
                global_histroy <= global_histroy;
            end
        end
    end

    /* update */
    logic update_we;
    weight_t updated_weight_value;

    `ifdef PERCEPTRON
        logic update_pred;
        logic [WEIGHT_WIDTH-1:0] update_y_abs;
        assign update_pred = ~ update_weight.y[WEIGHT_WIDTH-1]; // sign (>= 0 ?)
        assign update_y_abs = update_pred ? update_weight.y : (~update_weight.y + 1'b1);

        assign update_we = (update_pred ^ actual) || (update_y_abs <= WEIGHT_WIDTH'(THETA));
        assign updated_weight_value[WEIGHT_NUM-1] =
                update_weight.weights[WEIGHT_NUM-1] + (actual ? 1 : -1);
        generate
            for (genvar i = 0; i < WEIGHT_NUM - 1; i++) begin
                assign updated_weight_value[i] =
                        update_weight.weights[i]
                        + ((actual ^ update_weight.history[i]) ? -1 : 1);
            end
        endgenerate
    `else /* BIMODAL || GSHARE */
        assign update_we = update;
        always_comb begin
            case (update_weight)
                STRONGLY_UNTAKEN:
                    updated_weight_value = actual ? WEAKLY_UNTAKEN : STRONGLY_UNTAKEN;
                WEAKLY_UNTAKEN:
                    updated_weight_value = actual ? WEAKLY_TAKEN   : STRONGLY_UNTAKEN;
                WEAKLY_TAKEN:
                    updated_weight_value = actual ? STRONGLY_TAKEN : WEAKLY_UNTAKEN;
                STRONGLY_TAKEN:
                    updated_weight_value = actual ? STRONGLY_TAKEN : WEAKLY_TAKEN;
                default:
                    updated_weight_value = NONE;
            endcase
        end
    `endif

    /* table */
    logic [TABLE_WIDTH-1:0] dout_1_dummy;
    rip_2r1w_bram #(
        .DATA_WIDTH(TABLE_WIDTH),
        .ADDR_WIDTH(TABLE_DEPTH)
    ) bp_table (
        .clk(clk),
        .enable_1(rstn),
        .enable_2(rstn),
        .addr_1(update_index),
        .addr_2(current_index),
        .we_1(update_we),
        .din_1(updated_weight_value),
        .dout_1(dout_1_dummy), // ignored
        .dout_2(current_weight)
    );

endmodule

`default_nettype wire

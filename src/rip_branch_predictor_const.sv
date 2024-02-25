`ifndef RIP_BRANCH_PREDICTOR_CONST
`define RIP_BRANCH_PREDICTOR_CONST

package rip_branch_predictor_const;

    import rip_config::*;

    /*
    * HISTORY_LEN: branch history length
    * TABLE_DEPTH: depth of weight table
    * TABLE_WIDTH: width of weight table

    * bp_index_t: branch predictor table index public type
    * bp_weight_t: branch predictor weight public type
    * weight_t: branch predictor weight private type
    */

    localparam int TABLE_DEPTH = BP_PC_MSB - BP_PC_LSB + 1;
    typedef logic [TABLE_DEPTH-1 : 0] bp_index_t;

    `ifdef PERCEPTRON
        localparam int HISTORY_LEN = BP_HISTORY_LEN;

        /*
        * THETA: threashold
        * WEIGHT_WIDTH: width of each weight
        * WEIGHT_NUM: the number of weights (+1 for bias)
        */
        localparam int THETA = int'($floor(1.93 * real'(HISTORY_LEN) + 14));
        localparam int WEIGHT_WIDTH = $clog2(THETA+1) + 1;
        localparam int WEIGHT_NUM = HISTORY_LEN + 1;

        localparam int TABLE_WIDTH = WEIGHT_WIDTH * WEIGHT_NUM;
        typedef logic [WEIGHT_NUM-1:0][WEIGHT_WIDTH-1:0] weight_t;
        typedef struct packed {
            logic [HISTORY_LEN-1:0] history;
            weight_t weights;
            logic [WEIGHT_WIDTH-1:0] y;
        } bp_weight_t;
    `else /* BIMODAL || GSHARE */
        localparam int HISTORY_LEN = TABLE_DEPTH;

        localparam int TABLE_WIDTH = 2; // 2-bit saturating counter
        typedef logic [TABLE_WIDTH-1:0] weight_t;
        typedef enum logic [TABLE_WIDTH-1:0] {
            STRONGLY_UNTAKEN = 'b00,
            WEAKLY_UNTAKEN   = 'b01,
            WEAKLY_TAKEN     = 'b10,
            STRONGLY_TAKEN   = 'b11,
            NONE = 'x
        } bp_weight_t;
    `endif

endpackage

`endif

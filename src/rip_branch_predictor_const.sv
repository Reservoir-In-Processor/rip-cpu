`ifndef RIP_BRANCH_PREDICTOR_CONST
`define RIP_BRANCH_PREDICTOR_CONST

package rip_branch_predictor_const;

    import rip_config::*;

    /*
    * HISTORY_LEN: branch history length
    * TABLE_DEPTH: depth of weight table
    * TABLE_WIDTH: width of weight table

    * bp_index_t: branch predictor table index type
    * bp_weight_t: branch predictor weight (bpw) type
    */

    localparam int TABLE_DEPTH = BP_PC_MSB - BP_PC_LSB + 1;
    typedef logic [TABLE_DEPTH-1 : 0] bp_index_t;

    localparam int HISTORY_LEN = TABLE_DEPTH;

    localparam int TABLE_WIDTH = 2; // 2-bit saturating counter
    typedef enum logic [1:0] {
        STRONGLY_UNTAKEN = 'b00,
        WEAKLY_UNTAKEN   = 'b01,
        WEAKLY_TAKEN     = 'b10,
        STRONGLY_TAKEN   = 'b11,
        NONE = 'x
    } bp_weight_t;

endpackage

`endif

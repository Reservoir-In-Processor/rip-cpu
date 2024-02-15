`ifndef RIP_BRANCH_PREDICTOR_CONST
`define RIP_BRANCH_PREDICTOR_CONST

package rip_branch_predictor_const;

   // branch predictor weight (bpw) type
    typedef enum logic [1:0] {
        STRONGLY_UNTAKEN = 'b00,
        WEAKLY_UNTAKEN   = 'b01,
        WEAKLY_TAKEN     = 'b10,
        STRONGLY_TAKEN   = 'b11,
        NONE = 'x
    } rip_bpw_t;

endpackage

`endif

`default_nettype none
`timescale 1ns / 1ps

module rip_core
    import rip_type::*;
    import rip_const::*;
    import rip_config::*;
    import rip_branch_predictor_const::*;
#(
    parameter int REG_ADDR_WIDTH = 5,
    parameter int CSR_ADDR_WIDTH = 12,
    parameter int DATA_WIDTH = 32,
    parameter int AXI_ID_WIDTH = 4,
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 32
) (
    input wire sys_rst_n,
    input wire clk,

    // control signals
    input wire run,
    output logic busy,
    // CMA region start addresses
    input wire [AXI_ADDR_WIDTH-1:0] mem_head, // program data
    input wire [AXI_ADDR_WIDTH-1:0] ret_head, // return data

`ifdef VERILATOR
    output wire [DATA_WIDTH-1:0] riscv_tests_passed
`else
    rip_axi_interface.master M_AXI
`endif  // VERILATOR
);
    localparam NUM_COL = DATA_WIDTH / B_WIDTH; // number of columns in memory

    csr_t csr;
    core_mode_t mode;

    logic rst_n;

    assign rst_n = sys_rst_n && busy;
    /*
        ~sys_rst_n | run | busy | ~rst_n
        -|-|-|-
        0 | 0 | 0 | 1
        0 | 0 | 1 | 0 (busy)
        0 | 1 | 0 | 1 (start)
        0 | 1 | 1 | 0 (busy)
        1 | 0 | 0 | 1
        1 | 0 | 1 | 1
        1 | 1 | 0 | 1
        1 | 1 | 1 | 1
    */

    logic [AXI_ADDR_WIDTH-1:0] mem_offset;
    logic [AXI_ADDR_WIDTH-1:0] ret_offset;

    always_ff @(posedge clk) begin
        if (~sys_rst_n) begin
            busy <= '0;
            mem_offset <= '0;
            ret_offset <= '0;
        end else begin
            if (~busy) begin
                if (run) begin
                    busy <= '1;
                    mem_offset <= mem_head;
                    ret_offset <= ret_head;
                end
            end else begin
                if (mode == FINISHED) begin // todo
                    busy <= '0;
                end
            end
        end
    end

    /* -------------------------------- *
     * Stage 0: PC (program counter)    *
     * -------------------------------- */

    state_t pc_state, pc_state_reg;
    logic [DATA_WIDTH-1:0] pc;
    logic [DATA_WIDTH-1:0] pc_next;
    logic [DATA_WIDTH-1:0] pc_next_buf;
    logic pc_next_buf_valid;

    logic pc_pred_taken;
    logic [DATA_WIDTH-1:0] pc_if_taken;
    logic [DATA_WIDTH-1:0] pc_with_pred;

    always_comb begin
        pc_pred_taken = de_state.READY & if_b_type & if_pred;
        pc_if_taken = if_pc + if_imm;
        pc_with_pred = pc_pred_taken ? pc_if_taken : pc;

        if (pc_state_reg.INVALID) begin
            pc_state = 3'b100;
        end
        else if (busy_1 | busy_2) begin
            pc_state = 3'b010;
        end
        else begin
            pc_state = pc_state_reg;
        end

        if (ma_state.READY & ex_inst.UPDATE_PC) begin
            if (ex_inst.JALR) begin
                pc_next = (ex_rs1 + ex_imm) & 32'hFFFFFFFE;
            end
            else if ((ex_inst.JAL | ex_inst.JALR) |
                     (ex_alu_rslt[0] & (ex_inst.BEQ | ex_inst.BNE | ex_inst.BLT | ex_inst.BGE |
                                        ex_inst.BLTU | ex_inst.BGEU))) begin
                pc_next = ex_pc + ex_imm;
            end
            else if (ex_inst.ECALL) begin
                pc_next = csr.mtvec;
            end
            else if (ex_inst.MRET) begin
                pc_next = csr.mepc;
            end
            else begin
                pc_next = ex_pc + 32'h4;
            end
        end
        else begin
            pc_next = pc_with_pred + 32'h4;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pc_state_reg <= 3'b100;
            pc       <= -32'h4;
        end
        else begin
            if (ex_stall_by_load) begin
                pc_state_reg <= 3'b010;
            end
            else begin
                pc_state_reg <= 3'b001;
            end

            if (pc_state.READY) begin
                if (pc_next_buf_valid) begin
                    pc <= pc_next_buf;
                    pc_next_buf_valid <= 1'b0;
                end
                else begin
                    pc <= pc_next;
                end
            end

            if (pc_state.STALL & !if_state.STALL & !pc_next_buf_valid) begin
                pc_next_buf <= pc_next;
                pc_next_buf_valid <= 1'b1;
            end
        end
    end

    /* -------------------------------- *
     * Stage 1: IF (instruction fetch)  *
     * -------------------------------- */

    state_t if_state, if_state_reg;
    logic [DATA_WIDTH-1:0] if_pc;
    wire [DATA_WIDTH-1:0] if_inst_code;

    wire [REG_ADDR_WIDTH-1:0] if_rs1_num;
    wire [REG_ADDR_WIDTH-1:0] if_rs2_num;
    wire [REG_ADDR_WIDTH-1:0] if_rd_num;
    wire [CSR_ADDR_WIDTH-1:0] if_csr_num;

    wire [DATA_WIDTH-1:0] if_dout;

    wire if_b_type;
    wire [DATA_WIDTH-1:0] if_imm;
    bp_index_t if_pred_index;
    bp_weight_t if_pred_weight;
    logic if_pred;

    // assign if_inst_code = (de_state.READY & !ex_state.STALL) ? if_dout : 32'h0;
    assign if_inst_code = if_dout;

    always_comb begin
        if (if_state_reg.INVALID) begin
            if_state = 3'b100;
        end
        else if (busy_1 | busy_2) begin
            if_state = 3'b010;
        end
        else begin
            if_state = if_state_reg;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            if_state_reg <= 3'b100;
            if_pc    <= 32'h0;
        end
        else begin
            if ((!pc_state.READY & !if_state.STALL) | ex_flush_by_jmp) begin
                if_state_reg <= 3'b100;
            end
            else if (ex_stall_by_load) begin
                if_state_reg <= 3'b010;
            end
            else begin
                if_state_reg <= 3'b001;
            end

            if (if_state.READY) begin
                if_pc <= pc_with_pred;
                if_pred_index <= pred_index;
                if_pred_weight <= pred_weight;
                if_pred <= pred;
            end
            else if (!de_state.STALL) begin
                if_pc <= 32'h0;
            end
        end
    end

    /* -------------------------------- *
     * Stage 2: DE (decode)             *
     * -------------------------------- */

    state_t de_state, de_state_reg;
    logic [DATA_WIDTH-1:0] de_pc;
    inst_t de_inst;

    logic [REG_ADDR_WIDTH-1:0] de_rs1_num;
    logic [REG_ADDR_WIDTH-1:0] de_rs2_num;
    logic [REG_ADDR_WIDTH-1:0] de_rd_num;
    logic [CSR_ADDR_WIDTH-1:0] de_csr_num;

    wire [DATA_WIDTH-1:0] de_rs1_reg;
    wire [DATA_WIDTH-1:0] de_rs2_reg;
    logic [DATA_WIDTH-1:0] de_rs1;
    logic [DATA_WIDTH-1:0] de_rs2;
    wire [DATA_WIDTH-1:0] de_imm;
    wire [REG_ADDR_WIDTH-1:0] de_csr_zimm;
    logic [DATA_WIDTH-1:0] de_csr_reg;
    logic [DATA_WIDTH-1:0] de_csr;

    logic de_b_type;
    bp_index_t de_pred_index;
    bp_weight_t de_pred_weight;
    logic de_pred;
    logic branch_result;

    rip_decode decode (
        .rst_n(rst_n),
        .clk(clk),
        .de_ready(de_state.READY),
        .ex_stall(de_state.STALL),

        .inst_code(if_inst_code),

        .if_b_type(if_b_type),
        .if_imm(if_imm),

        .if_rs1_num(if_rs1_num),
        .if_rs2_num(if_rs2_num),
        .if_rd_num (if_rd_num),
        .if_csr_num(if_csr_num),

        .de_rs1_num(de_rs1_num),
        .de_rs2_num(de_rs2_num),
        .de_rd_num (de_rd_num),
        .de_csr_num(de_csr_num),

        .csr_zimm(de_csr_zimm),

        .imm(de_imm),

        .inst(de_inst)
    );

    // forwarding register
    always_comb begin
        if (ma_state.READY && !ex_inst.ACCESS_MEM && !ex_inst.UPDATE_CSR && ex_rd_num != 5'h0 &&
            de_rs1_num == ex_rd_num) begin
            de_rs1 = ex_alu_rslt;
        end
        else if (wb_state.READY && !ma_inst.UPDATE_CSR && ma_rd_num != 5'h0 &&
                 de_rs1_num == ma_rd_num) begin
            de_rs1 = ma_wdata;
        end
        else if (after_wb_state.READY && !wb_inst.UPDATE_CSR && wb_rd_num != 5'h0 &&
                 de_rs1_num == wb_rd_num) begin
            de_rs1 = wb_wdata;
        end
        else begin
            de_rs1 = de_rs1_reg;
        end

        if (ma_state.READY && !ex_inst.ACCESS_MEM && !ex_inst.UPDATE_CSR && ex_rd_num != 5'h0 &&
            de_rs2_num == ex_rd_num) begin
            de_rs2 = ex_alu_rslt;
        end
        else if (wb_state.READY && !ma_inst.UPDATE_CSR && ma_rd_num != 5'h0 &&
                 de_rs2_num == ma_rd_num) begin
            de_rs2 = ma_wdata;
        end
        else if (after_wb_state.READY && !wb_inst.UPDATE_CSR && wb_rd_num != 5'h0 &&
                 de_rs2_num == wb_rd_num) begin
            de_rs2 = wb_wdata;
        end
        else begin
            de_rs2 = de_rs2_reg;
        end
    end

    // assign de_csr_reg = read_csr(csr, if_csr_num);
    always_ff @(posedge clk) begin
        de_csr_reg <= rip_csr::read_csr(csr, if_csr_num);
    end

    // forwarding csr register
    always_comb begin
        if (de_state_reg.INVALID) begin
            de_state = 3'b100;
        end
        else if (busy_1 | busy_2) begin
            de_state = 3'b010;
        end
        else begin
            de_state = de_state_reg;
        end

        if (ma_state.READY && ex_inst.UPDATE_CSR && if_csr_num == ex_csr_num) begin
            de_csr = ex_alu_rslt;
        end
        else if (wb_state.READY && ma_inst.UPDATE_CSR && if_csr_num == ma_csr_num) begin
            de_csr = ma_alu_rslt;
        end
        else begin
            de_csr = de_csr_reg;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            de_state_reg   <= 3'b100;
            de_pc      <= 32'h0;
        end
        else begin
            if ((!if_state.READY & !de_state.STALL) | ex_flush_by_jmp) begin
                de_state_reg <= 3'b100;
            end
            else if (ex_stall_by_load) begin
                de_state_reg <= 3'b010;
            end
            else begin
                de_state_reg <= 3'b001;
            end

            if (de_state.READY) begin
                de_pc <= if_pc;
                de_b_type <= if_b_type;
                de_pred_index <= if_pred_index;
                de_pred_weight <= if_pred_weight;
                de_pred <= if_pred;
            end
            else if (!ex_state.STALL) begin
                de_pc <= 32'h0;
            end
        end
    end

    bp_index_t pred_index;
    bp_weight_t pred_weight;
    wire pred;
    logic update;
    bp_index_t update_index;
    bp_weight_t update_weight;
    logic actual;

    logic branch_correct;

    assign update = ex_state.READY & de_b_type;
    assign update_index = de_pred_index;
    assign update_weight = de_pred_weight;
    assign actual = branch_result;
    assign branch_correct = de_b_type & (actual == de_pred);
    rip_branch_predictor branch_predictor (
        .clk(clk),
        .rstn(rst_n),
        .pc(pc),
        .pred_index(pred_index),
        .pred_weight(pred_weight),
        .pred(pred),
        .update(update),
        .update_index(update_index),
        .update_weight(update_weight),
        .actual(actual)
    );

    /* -------------------------------- *
     * Stage 3: EX (execution)          *
     * -------------------------------- */

    state_t ex_state, ex_state_reg;
    logic [DATA_WIDTH-1:0] ex_pc;
    inst_t ex_inst;
    wire ex_stall_by_load;
    wire ex_flush_by_jmp;

    logic [REG_ADDR_WIDTH-1:0] ex_rd_num;
    logic [CSR_ADDR_WIDTH-1:0] ex_csr_num;

    logic [DATA_WIDTH-1:0] ex_rs1;
    logic [DATA_WIDTH-1:0] ex_rs2;
    logic [DATA_WIDTH-1:0] ex_imm;

    logic [REG_ADDR_WIDTH-1:0] ex_csr_zimm;
    logic [DATA_WIDTH-1:0] ex_csr;

    wire [DATA_WIDTH-1:0] ex_alu_rslt;

    rip_alu alu (
        .rst_n(rst_n),
        .clk  (clk),
        .ex_ready(ex_state.READY),

        .inst(de_inst),

        .rs1 (de_rs1),
        .rs2 (de_rs2),
        .pc  (de_pc),
        .csr (de_csr),
        .imm (de_imm),
        .zimm(de_csr_zimm),

        .branch_result(branch_result),
        .rslt(ex_alu_rslt)
    );

    assign ex_stall_by_load = ex_state.READY &
        (de_inst.LB | de_inst.LH | de_inst.LW | de_inst.LBU | de_inst.LHU) & de_state.READY &
        (de_rd_num == if_rs1_num | de_rd_num == if_rs2_num);
    assign ex_flush_by_jmp = ex_state.READY & (de_inst.UPDATE_PC & !branch_correct);

    always_comb begin
        if (ex_state_reg.INVALID) begin
            ex_state = 3'b100;
        end
        else if (busy_1) begin
            ex_state = 3'b010;
        end
        else begin
            ex_state = ex_state_reg;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ex_state_reg    <= 3'b100;
            ex_pc       <= 32'h0;

            ex_rs1      <= 32'h0;
            ex_rs2      <= 32'h0;
            ex_imm      <= 32'h0;

            ex_csr_zimm <= 5'h0;
            ex_csr      <= 32'h0;

            ex_rd_num   <= 5'h0;
            ex_csr_num  <= 12'h0;
        end
        else begin
            if ((!de_state.READY && !ex_state.STALL) | ex_flush_by_jmp) begin
                ex_state_reg <= 3'b100;
            end
            else if (ex_stall_by_load) begin
                ex_state_reg <= 3'b010;
            end
            else begin
                ex_state_reg <= 3'b001;
            end

            if (ex_state.READY) begin
                ex_inst     <= de_inst;
                ex_pc       <= de_pc;

                ex_rs1      <= de_rs1;
                ex_rs2      <= de_rs2;
                ex_imm      <= de_imm;

                ex_csr_zimm <= de_csr_zimm;
                ex_csr      <= de_csr;

                ex_rd_num   <= de_rd_num;
                ex_csr_num  <= de_csr_num;
            end
            else if (!ma_state.STALL) begin
                ex_inst     <= 0;
                ex_pc       <= 32'h0;

                ex_rs1      <= 32'h0;
                ex_rs2      <= 32'h0;
                ex_imm      <= 32'h0;

                ex_csr_zimm <= 5'h0;
                ex_csr      <= 32'h0;

                ex_rd_num   <= 5'h0;
                ex_csr_num  <= 12'h0;
            end
        end
    end

    // csr
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            csr.mstatus = 32'h0;
            csr.mtvec   = 32'h0;
            csr.mepc    = 32'h0;
            csr.mcause  = 32'h0;
            csr.cycle   = 32'h0;
        end
        else begin
            if (mode == RUNNING) begin
                csr.cycle = csr.cycle + 32'h1;
            end

            if (ex_state.READY && de_b_type) begin
                if (branch_correct && de_pred) begin
                    csr.bptp = csr.bptp + 32'h1;
                end
                else if (branch_correct && !de_pred) begin
                    csr.bptn = csr.bptn + 32'h1;
                end
                else if (!branch_correct && de_pred) begin
                    csr.bpfp = csr.bpfp + 32'h1;
                end
                else begin
                    csr.bpfn = csr.bpfn + 32'h1;
                end
            end

            if (ma_csr_wen) begin
                rip_csr::write_csr(csr, ma_csr_num, ma_alu_rslt);
            end
            // ECALL execution
            if (ex_state.READY && de_inst.ECALL) begin
                csr.mcause = CAUSE_ECALL;
                csr.mepc   = ex_pc;
            end
            // illegal instruction: update read-only CSR
            // except [csrr XX, YY] := [csrrs XX, zero, YY]
            if (ex_state.READY && de_inst.UPDATE_CSR && de_csr_num[11:10] == 2'b11 &&
                !(de_inst.CSRRS && de_rs1 == 32'h0)) begin
                csr.mcause = CAUSE_ILLEGAL_INST;
                csr.mepc   = ex_pc;
            end
        end
    end

    // core mode
    always_ff @(posedge clk) begin
        if (!sys_rst_n) begin
            mode = FINISHED;
        end
        else if (!rst_n) begin
            mode = RUNNING;
        end
        else begin
            if (ex_state.READY && de_inst.EXTX) begin
                mode = EXITPROC;
            end
            else if (ex_state.READY && de_inst.EXT) begin
                mode = FINISHED;
            end
        end
    end

    /* -------------------------------- *
     * Stage 4: MA (memory access)      *
     * -------------------------------- */

    state_t ma_state, ma_state_reg;
    inst_t ma_inst;
    wire ma_stall_by_load;

    logic [DATA_WIDTH-1:0] ma_alu_rslt;
    logic [REG_ADDR_WIDTH-1:0] ma_rd_num;
    logic [CSR_ADDR_WIDTH-1:0] ma_csr_num;
    logic [DATA_WIDTH-1:0] ma_csr;

    wire [DATA_WIDTH-1:0] ma_ram_dout;

    always_comb begin
        if (ma_state_reg.INVALID) begin
            ma_state = 3'b100;
        end
        else if (busy_1) begin
            ma_state = 3'b010;
        end
        else begin
            ma_state = ma_state_reg;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ma_state_reg    <= 3'b100;
            ma_alu_rslt <= 32'h0;

            ma_rd_num   <= 5'h0;
            ma_csr_num  <= 12'h0;
            ma_csr      <= 32'h0;
        end
        else begin
            if (!ex_state.READY & !ma_state.STALL) begin
                ma_state_reg <= 3'b100;
            end
            else begin
                ma_state_reg <= 3'b001;
            end

            if (ma_state.READY) begin
                ma_inst     <= ex_inst;
                ma_alu_rslt <= ex_alu_rslt;

                ma_rd_num   <= ex_rd_num;
                ma_csr_num  <= ex_csr_num;
                ma_csr      <= ex_csr;
            end
            else if (!wb_state.STALL) begin
                ma_inst     <= 0;
                ma_alu_rslt <= 32'h0;

                ma_rd_num   <= 5'h0;
                ma_csr_num  <= 12'h0;
                ma_csr      <= 32'h0;
            end
        end
    end

    wire [NUM_COL-1:0] we_1;
    wire re_1;
    wire re_2;
    wire [DATA_WIDTH-1:0] addr_1;
    wire [DATA_WIDTH-1:0] addr_2;
    wire [DATA_WIDTH-1:0] din_1;
    wire [DATA_WIDTH-1:0] dout_1;
    wire [DATA_WIDTH-1:0] dout_2;
    wire busy_1;
    wire busy_2;

    rip_memory_access memory_access (
        .clk(clk),

        .we_1(we_1),
        .re_1(re_1),
        .re_2(re_2),
        .addr_1(addr_1),
        .addr_2(addr_2),
        .din_1(din_1),
        .dout_1(dout_1),
        .dout_2(dout_2),

        .if_ready(if_state.READY),
        .pc(pc_with_pred),
        .if_dout(if_dout),

        .ma_ready(ma_state.READY),
        .ex_inst (ex_inst),
        .ma_inst (ma_inst),
        .ex_addr (ex_alu_rslt),
        .ma_addr (ma_alu_rslt),
        .ex_din  (ex_rs2),
        .ma_dout (ma_ram_dout)
    );

    wire [DATA_WIDTH-1:0] mmu_addr_1;
    wire [DATA_WIDTH-1:0] mmu_addr_2;

    assign mmu_addr_1 = addr_1 | (mode == RUNNING ? mem_offset : ret_offset);
    assign mmu_addr_2 = addr_2 | mem_offset;

`ifdef VERILATOR
    rip_mmu_stub mmu_stub (
        .clk(clk),
        .rstn(rst_n),

        .we_1(we_1),
        .re_1(re_1),
        .re_2(re_2),
        .addr_1(mmu_addr_1),
        .addr_2(mmu_addr_2),
        .din_1(din_1),
        .dout_1(dout_1),
        .dout_2(dout_2),
        .busy_1(busy_1),
        .busy_2(busy_2)
    );
`else
    rip_memory_management_unit #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) memory_management_unit (
        .clk(clk),
        .rstn(rst_n),

        .we_1(we_1),
        .re_1(re_1),
        .re_2(re_2),
        .addr_1(mmu_addr_1),
        .addr_2(mmu_addr_2),
        .din_1(din_1),
        .dout_1(dout_1),
        .dout_2(dout_2),
        .busy_1(busy_1),
        .busy_2(busy_2),
        .M_AXI(M_AXI)
    );
`endif  // VERILATOR

    /* -------------------------------- *
     * Stage 5: WB (write back)         *
     * -------------------------------- */

    state_t wb_state, wb_state_reg;
    inst_t wb_inst;

    wire ma_reg_wen;
    wire ma_csr_wen;
    logic [DATA_WIDTH-1:0] ma_wdata;

    logic [REG_ADDR_WIDTH-1:0] wb_rd_num;
    logic [DATA_WIDTH-1:0] wb_wdata;

    assign ma_reg_wen = wb_state.READY && ma_inst.UPDATE_REG;
    assign ma_csr_wen = wb_state.READY && ma_inst.UPDATE_CSR;
    always_comb begin
        if (wb_state_reg.INVALID) begin
            wb_state = 3'b100;
        end
        else if (busy_1) begin
            wb_state = 3'b010;
        end
        else begin
            wb_state = wb_state_reg;
        end

        if (ma_inst.LB | ma_inst.LH | ma_inst.LW | ma_inst.LBU | ma_inst.LHU) begin
            ma_wdata = ma_ram_dout;
        end
        else if (ma_inst.UPDATE_CSR) begin
            ma_wdata = ma_csr;
        end
        else begin
            ma_wdata = ma_alu_rslt;
        end
    end

    rip_regfile regfile (
        .rst_n(rst_n),
        .clk  (clk),

        .de_ready(de_state.READY),
        .ma_rd_num(ma_rd_num),
        .wen(ma_reg_wen),
        .wdata(ma_wdata),

        .if_rs1_num(if_rs1_num),
        .if_rs2_num(if_rs2_num),

        .rs1(de_rs1_reg),
        .rs2(de_rs2_reg)
    );

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wb_state_reg <= 3'b100;
            wb_rd_num <= 5'h0;
            wb_wdata  <= 32'h0;
        end
        else begin
            if (!ma_state.READY & !wb_state.STALL) begin
                wb_state_reg <= 3'b100;
            end
            else begin
                wb_state_reg <= 3'b001;
            end
        end

        if (wb_state.READY) begin
            wb_rd_num <= ma_rd_num;
            wb_wdata  <= ma_wdata;
            wb_inst   <= ma_inst;
        end
        else if (!after_wb_state.STALL) begin
            wb_rd_num <= 5'h0;
            wb_wdata  <= 32'h0;
            wb_inst   <= 0;
        end
    end

    /* -------------------------------- *
     * After WB (for forwarding)        *
     * -------------------------------- */

    state_t after_wb_state, after_wb_state_reg;

    always_comb begin
        if (after_wb_state_reg.INVALID) begin
            after_wb_state = 3'b100;
        end
        else begin
            after_wb_state = after_wb_state_reg;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            after_wb_state_reg <= 3'b100;
        end
        else begin
            if (!wb_state.READY & !after_wb_state.STALL) begin
                after_wb_state_reg <= 3'b100;
            end
            else begin
                after_wb_state_reg <= 3'b001;
            end
        end
    end


`ifdef VERILATOR
    integer file_handle, t;
    logic [DATA_WIDTH-1:0] de_inst_code, ex_inst_code, ma_inst_code, wb_inst_code;
    logic [DATA_WIDTH-1:0] ma_pc, wb_pc;
    logic finished;

    assign riscv_tests_passed = regfile.regfile[3];

    initial begin
        file_handle = $fopen("dump.txt");
        t           = 0;
    end

    always_ff @(posedge clk) begin
        assert (!(pc_state.READY & if_state.STALL));
        assert (!(if_state.READY & de_state.STALL));
        assert (!(de_state.READY & ex_state.STALL));
        assert (!(ex_state.READY & ma_state.STALL));
        assert (!(ma_state.READY & wb_state.STALL));
    end

    always_ff @(posedge clk) begin
        t <= t + 10;

        if (!rst_n) begin
            de_inst_code   <= 32'h0;
            ex_inst_code   <= 32'h0;
            ma_inst_code   <= 32'h0;
            wb_inst_code   <= 32'h0;
        end
        else begin
            if (de_state.READY) de_inst_code <= if_inst_code;
            if (ex_state.READY) ex_inst_code <= de_inst_code;
            if (ma_state.READY) begin
                ma_inst_code <= ex_inst_code;
                ma_pc        <= ex_pc;
            end
            if (wb_state.READY) begin
                wb_inst_code <= ma_inst_code;
                wb_pc        <= ma_pc;
            end
        end

        if (after_wb_state.READY & !finished) begin
            $fdisplay(file_handle, "Inst @ %X (%d ps)\n???  := %b(BIN) = %X (HEX LE)", wb_pc, t,
                      wb_inst_code, wb_inst_code);
            $fdisplay(file_handle, "Regs after:");
            $fdisplay(
                file_handle, "x0 (zero):= %X, x1 ( ra ):= %X, x2 ( sp ):= %X, x3 ( gp ):= %X, ",
                regfile.regfile[0], regfile.regfile[1], regfile.regfile[2], regfile.regfile[3]);
            $fdisplay(
                file_handle, "x4 ( tp ):= %X, x5 ( t0 ):= %X, x6 ( t1 ):= %X, x7 ( t2 ):= %X, ",
                regfile.regfile[4], regfile.regfile[5], regfile.regfile[6], regfile.regfile[7]);
            $fdisplay(
                file_handle, "x8 ( s0 ):= %X, x9 ( s1 ):= %X, x10( a0 ):= %X, x11( a1 ):= %X, ",
                regfile.regfile[8], regfile.regfile[9], regfile.regfile[10], regfile.regfile[11]);
            $fdisplay(
                file_handle, "x12( a2 ):= %X, x13( a3 ):= %X, x14( a4 ):= %X, x15( a5 ):= %X, ",
                regfile.regfile[12], regfile.regfile[13], regfile.regfile[14], regfile.regfile[15]);
            $fdisplay(
                file_handle, "x16( a6 ):= %X, x17( a7 ):= %X, x18( s2 ):= %X, x19( s3 ):= %X, ",
                regfile.regfile[16], regfile.regfile[17], regfile.regfile[18], regfile.regfile[19]);
            $fdisplay(
                file_handle, "x20( s4 ):= %X, x21( s5 ):= %X, x22( s6 ):= %X, x23( s7 ):= %X, ",
                regfile.regfile[20], regfile.regfile[21], regfile.regfile[22], regfile.regfile[23]);
            $fdisplay(
                file_handle, "x24( s8 ):= %X, x25( s9 ):= %X, x26( s10):= %X, x27( s11):= %X, ",
                regfile.regfile[24], regfile.regfile[25], regfile.regfile[26], regfile.regfile[27]);
            $fdisplay(
                file_handle, "x28( t3 ):= %X, x29( t4 ):= %X, x30( t5 ):= %X, x31( t6 ):= %X, \n",
                regfile.regfile[28], regfile.regfile[29], regfile.regfile[30], regfile.regfile[31]);

            // $fdisplay(file_handle, "  satp  := %X,  mstatus:= %X,  medeleg:= %X,  mideleg:= %X, ",
            //           32'h0, csr.mstatus, 32'h0, 32'h0);
            // $fdisplay(file_handle, "   mie  := %X,   mtvec := %X,   mepc  := %X,  mcause := %X, ",
            //           32'h0, csr.mtvec, csr.mepc, csr.mcause);
            // $fdisplay(file_handle, "  mtval := %X,  pmpcfg := %X,  pmpaddr:= %X,  mhartid:= %X, \n",
            //           32'h0, 32'h0, 32'h0, 32'h0);

            // finish simulation when invalid instruction is executed
            if (wb_inst.EBREAK) begin
                $fclose(file_handle);
            end
        end
    end
`endif  // VERILATOR
endmodule: rip_core

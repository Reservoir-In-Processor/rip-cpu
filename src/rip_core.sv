`default_nettype none
`timescale 1ns / 1ps

`include "rip_common.sv"

module rip_core #(
    parameter int START_ADDR = 32'h00008000
) (
    input rst_n,
    input clk
`ifdef VERILATOR
    , output wire [31:0] riscv_tests_passed
`endif  // VERILATOR
);
    import rip_common::*;

    csr_t csr;

    typedef struct packed {
        logic INVALID;
        logic STALL;
        logic READY;
    } state_t;

    /* -------------------------------- *
     * Stage 0: PC (program counter)    *
     * -------------------------------- */

    state_t pc_state;
    logic [31:0] pc;
    logic [31:0] pc_next;

    always_comb begin
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
            pc_next = pc + 32'h4;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pc_state <= 3'b100;
            pc       <= START_ADDR - 32'h4;
        end
        else begin
            if (ex_stall_by_load) begin
                pc_state <= 3'b010;
            end
            else begin
                pc_state <= 3'b001;
            end

            if (pc_state.READY) begin
                pc <= pc_next;
            end
            else if (!if_state.STALL) begin
                pc <= START_ADDR - 32'h4;
            end
        end
    end

    /* -------------------------------- *
     * Stage 1: IF (instruction fetch)  *
     * -------------------------------- */

    state_t if_state;
    logic [31:0] if_pc;
    wire [31:0] if_inst_code;

    wire [4:0] if_rs1_num;
    wire [4:0] if_rs2_num;
    wire [4:0] if_rd_num;
    wire [11:0] if_csr_num;

    wire [31:0] if_dout;

    assign if_inst_code = (de_state.READY & !ex_state.STALL) ? if_dout : 32'h0;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            if_state <= 3'b100;
            if_pc    <= 32'h0;
        end
        else begin
            if (pc_state.INVALID | ex_flush_by_jmp) begin
                if_state <= 3'b100;
            end
            else if (ex_stall_by_load) begin
                if_state <= 3'b010;
            end
            else begin
                if_state <= 3'b001;
            end

            if (if_state.READY) begin
                if_pc <= pc;
            end
            else if (!de_state.STALL) begin
                if_pc <= 32'h0;
            end
        end
    end

    /* -------------------------------- *
     * Stage 2: DE (decode)             *
     * -------------------------------- */

    state_t de_state;
    logic [31:0] de_pc;
    inst_t de_inst;

    logic [4:0] de_rs1_num;
    logic [4:0] de_rs2_num;
    logic [4:0] de_rd_num;
    logic [11:0] de_csr_num;

    wire [31:0] de_rs1_reg;
    wire [31:0] de_rs2_reg;
    logic [31:0] de_rs1;
    logic [31:0] de_rs2;
    wire [31:0] de_imm;
    wire [4:0] de_csr_zimm;
    logic [31:0] de_csr_reg;
    logic [31:0] de_csr;

    rip_decode decode (
        .rst_n(rst_n),
        .clk(clk),
        .de_ready(de_state.READY),
        .ex_stall(de_state.STALL),

        .inst_code(if_inst_code),

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
        if (ma_state.READY && !ex_inst.UPDATE_CSR && ex_rd_num != 5'h0 &&
            de_rs1_num == ex_rd_num) begin
            de_rs1 = ex_alu_rslt;
        end
        else if (wb_state.READY && !ma_inst.UPDATE_CSR && ma_rd_num != 5'h0 &&
                 de_rs1_num == ma_rd_num) begin
            de_rs1 = ma_wdata;
        end
        else begin
            de_rs1 = de_rs1_reg;
        end

        if (ma_state.READY && !ex_inst.UPDATE_CSR && ex_rd_num != 5'h0 &&
            de_rs2_num == ex_rd_num) begin
            de_rs2 = ex_alu_rslt;
        end
        else if (wb_state.READY && !ma_inst.UPDATE_CSR && ma_rd_num != 5'h0 &&
                 de_rs2_num == ma_rd_num) begin
            de_rs2 = ma_wdata;
        end
        else begin
            de_rs2 = de_rs2_reg;
        end
    end

    // assign de_csr_reg = read_csr(csr, if_csr_num);
    always_ff @(posedge clk) begin
        de_csr_reg <= read_csr(csr, if_csr_num);
    end

    // forwarding csr register
    always_comb begin
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
            de_state   <= 3'b100;
            de_pc      <= 32'h0;

            de_rd_num  <= 5'h0;
            de_csr_num <= 12'h0;
        end
        else begin
            if (if_state.INVALID | (!de_state.STALL & if_state.STALL) | ex_flush_by_jmp) begin
                de_state <= 3'b100;
            end
            else if (ex_stall_by_load) begin
                de_state <= 3'b010;
            end
            else begin
                de_state <= 3'b001;
            end

            if (de_state.READY) begin
                de_pc <= if_pc;
            end
            else if (!ex_state.STALL) begin
                de_pc <= 32'h0;
            end
        end
    end

    /* -------------------------------- *
     * Stage 3: EX (execution)          *
     * -------------------------------- */

    state_t ex_state;
    logic [31:0] ex_pc;
    inst_t ex_inst;
    wire ex_stall_by_load;
    wire ex_flush_by_jmp;

    logic [4:0] ex_rd_num;
    logic [11:0] ex_csr_num;

    logic [31:0] ex_rs1;
    logic [31:0] ex_rs2;
    logic [31:0] ex_imm;

    logic [4:0] ex_csr_zimm;
    logic [31:0] ex_csr;

    wire [31:0] ex_alu_rslt;

    rip_alu alu (
        .rst_n(rst_n),
        .clk  (clk),

        .inst(de_inst),

        .rs1 (de_rs1),
        .rs2 (de_rs2),
        .pc  (de_pc),
        .csr (de_csr),
        .imm (de_imm),
        .zimm(de_csr_zimm),

        .rslt(ex_alu_rslt)
    );

    assign ex_stall_by_load = ex_state.READY &
        (de_inst.LB | de_inst.LH | de_inst.LW | de_inst.LBU | de_inst.LHU) & de_state.READY &
        (de_rd_num == if_rs1_num | de_rd_num == if_rs2_num);
    assign ex_flush_by_jmp = ex_state.READY & de_inst.UPDATE_PC;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ex_state    <= 3'b100;
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
            if (de_state.INVALID | ex_flush_by_jmp) begin
                ex_state <= 3'b100;
            end
            else if (ex_stall_by_load) begin
                ex_state <= 3'b010;
            end
            else begin
                ex_state <= 3'b001;
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
        end
        else begin
            if (ma_csr_wen) begin
                write_csr(csr, ma_csr_num, ma_alu_rslt);
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

    /* -------------------------------- *
     * Stage 4: MA (memory access)      *
     * -------------------------------- */

    state_t ma_state;
    inst_t ma_inst;

    logic [31:0] ma_alu_rslt;
    logic [4:0] ma_rd_num;
    logic [11:0] ma_csr_num;
    logic [31:0] ma_csr;

    wire [31:0] ma_ram_dout;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ma_state    <= 3'b100;
            ma_alu_rslt <= 32'h0;

            ma_rd_num   <= 5'h0;
            ma_csr_num  <= 12'h0;
            ma_csr      <= 32'h0;
        end
        else begin
            if (ex_state.INVALID | (!ma_state.STALL & ex_state.STALL)) begin
                ma_state <= 3'b100;
            end
            else begin
                ma_state <= 3'b001;
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

    rip_memory memory (
        .clk(clk),

        .if_ready(if_state.READY),
        .pc(pc),
        .if_dout(if_dout),

        .ma_ready(ma_state.READY),
        .ex_inst (ex_inst),
        .ex_addr (ex_alu_rslt),
        .ex_din  (ex_rs2),
        .ma_dout (ma_ram_dout)
    );

    /* -------------------------------- *
     * Stage 5: WB (write back)         *
     * -------------------------------- */

    state_t wb_state;

    wire ma_reg_wen;
    wire ma_csr_wen;
    logic [31:0] ma_wdata;

    assign ma_reg_wen = wb_state.READY && ma_inst.UPDATE_REG;
    assign ma_csr_wen = wb_state.READY && ma_inst.UPDATE_CSR;
    always_comb begin
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
            wb_state <= 3'b100;
        end
        else begin
            if (ma_state.INVALID) begin
                wb_state <= 3'b100;
            end
            else begin
                wb_state <= 3'b001;
            end
        end
    end

`ifdef VERILATOR
    integer file_handle, t;
    logic  after_wb_ready;
    inst_t wb_inst;
    logic [31:0] de_inst_code, ex_inst_code, ma_inst_code, wb_inst_code;
    logic [31:0] ma_pc, wb_pc;
    logic finished;

    assign riscv_tests_passed = regfile.regfile[3];

    initial begin
        file_handle = $fopen("dump.txt");
        t           = 0;
        finished    = 1'b0;
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
            after_wb_ready <= 1'b0;
            de_inst_code   <= 32'h0;
            ex_inst_code   <= 32'h0;
            ma_inst_code   <= 32'h0;
            wb_inst_code   <= 32'h0;
        end
        else begin
            after_wb_ready <= wb_state.READY;
            if (de_state.READY) de_inst_code <= if_inst_code;
            if (ex_state.READY) ex_inst_code <= de_inst_code;
            if (ma_state.READY) begin
                ma_inst_code <= ex_inst_code;
                ma_pc        <= ex_pc;
            end
            if (wb_state.READY) begin
                wb_inst      <= ma_inst;
                wb_inst_code <= ma_inst_code;
                wb_pc        <= ma_pc;
            end
        end

        if (after_wb_ready & !finished) begin
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

            $fdisplay(file_handle, "  satp  := %X,  mstatus:= %X,  medeleg:= %X,  mideleg:= %X, ",
                      32'h0, csr.mstatus, 32'h0, 32'h0);
            $fdisplay(file_handle, "   mie  := %X,   mtvec := %X,   mepc  := %X,  mcause := %X, ",
                      32'h0, csr.mtvec, csr.mepc, csr.mcause);
            $fdisplay(file_handle, "  mtval := %X,  pmpcfg := %X,  pmpaddr:= %X,  mhartid:= %X, \n",
                      32'h0, 32'h0, 32'h0, 32'h0);

            // finish simulation when invalid instruction is executed
            if (wb_state.READY & !|wb_inst) begin
                $fclose(file_handle);
                finished <= 1'b1;
            end
        end
    end
`endif  // VERILATOR
endmodule: rip_core

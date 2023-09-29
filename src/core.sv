`default_nettype none
`timescale 1ns / 1ps

// `include "decode.sv"
// `include "regfile.sv"
// `include "csr.sv"
// `include "alu.sv"
// `include "ram.sv"

module riscoffee_core #(
    parameter START_ADDR = 32'h00008000  // for fib(10) simulation
) (
    input RST_N,
    input CLK
);

    typedef struct packed {
        logic INVALID;
        logic STALL;
        logic READY;
    } state;

    /* -------------------------------- *
     * Stage 0: PC (program counter)    *
     * -------------------------------- */

    state pc_state;
    logic [31:0] pc;
    logic [31:0] pc_next;

    always_comb begin
        if (ma_state.READY & ex_inst.UPDATE_PC) begin
            if (ex_inst.JALR) begin
                pc_next = (ex_rs1 + ex_imm) & 32'hFFFFFFFE;
            end else if ((ex_inst.JAL | ex_inst.JALR) | (ex_alu_rslt[0] & (ex_inst.BEQ | ex_inst.BNE | ex_inst.BLT | ex_inst.BGE | ex_inst.BLTU | ex_inst.BGEU))) begin
                pc_next = ex_pc + ex_imm;
            end else begin
                pc_next = ex_pc + 32'h4;
            end
        end else begin
            pc_next = pc + 32'h4;
        end
    end

    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            pc_state <= 3'b100;
            pc       <= START_ADDR - 32'h4;
        end else begin
            if (ex_stall_by_load) begin
                pc_state <= 3'b010;
            end else begin
                pc_state <= 3'b001;
            end

            if (pc_state.READY) begin
                pc <= pc_next;
            end else if (!if_state.STALL) begin
                pc <= START_ADDR - 32'h4;
            end
        end
    end

    /* -------------------------------- *
     * Stage 1: IF (instruction fetch)  *
     * -------------------------------- */

    state if_state;
    logic [31:0] if_pc;
    wire [31:0] if_inst_code;

    wire [4:0] if_rs1_num;
    wire [4:0] if_rs2_num;
    wire [4:0] if_rd_num;
    wire [11:0] if_csr_num;

    wire [31:0] if_dout;

    assign if_inst_code      = (de_state.READY & !ex_state.STALL) ? if_dout : 32'h0;

    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            if_state <= 3'b100;
            if_pc    <= 32'h0;
        end else begin
            if (pc_state.INVALID | ex_invalid_by_jmp) begin
                if_state <= 3'b100;
            end else if (ex_stall_by_load) begin
                if_state <= 3'b010;
            end else begin
                if_state <= 3'b001;
            end

            if (if_state.READY) begin
                if_pc <= pc;
            end else if (!de_state.STALL) begin
                if_pc <= 32'h0;
            end
        end
    end

    /* -------------------------------- *
     * Stage 2: DE (decode)             *
     * -------------------------------- */

    state de_state;
    logic [31:0] de_pc;
    inst de_inst;

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
    wire [31:0] de_csr;

    riscoffee_decode decode (
        .RST_N(RST_N),
        .CLK(CLK),
        .DE_READY(de_state.READY),
        .EX_STALL(de_state.STALL),

        .INST_CODE(if_inst_code),

        .IF_RS1_NUM(if_rs1_num),
        .IF_RS2_NUM(if_rs2_num),
        .IF_RD_NUM (if_rd_num),
        .IF_CSR_NUM(if_csr_num),

        .DE_RS1_NUM(de_rs1_num),
        .DE_RS2_NUM(de_rs2_num),
        .DE_RD_NUM (de_rd_num),
        .DE_CSR_NUM(de_csr_num),

        .CSR_ZIMM(de_csr_zimm),

        .IMM(de_imm),

        .INST(de_inst)
    );

    always_comb begin
        if (ma_state.READY && ex_rd_num != 5'h0 && de_rs1_num == ex_rd_num) begin
            de_rs1 = ex_alu_rslt;
        end else if (wb_state.READY && ma_rd_num != 5'h0 && de_rs1_num == ma_rd_num) begin
            de_rs1 = wb_wdata;
        end else begin
            de_rs1 = de_rs1_reg;
        end

        if (ma_state.READY && ex_rd_num != 5'h0 && de_rs2_num == ex_rd_num) begin
            de_rs2 = ex_alu_rslt;
        end else if (wb_state.READY && ma_rd_num != 5'h0 && de_rs2_num == ma_rd_num) begin
            de_rs2 = wb_wdata;
        end else begin
            de_rs2 = de_rs2_reg;
        end
    end

    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            de_state   <= 3'b100;
            de_pc      <= 32'h0;

            de_rd_num  <= 5'h0;
            de_csr_num <= 12'h0;
        end else begin
            if (if_state.INVALID | (!de_state.STALL & if_state.STALL) | ex_invalid_by_jmp) begin
                de_state <= 3'b100;
            end else if (ex_stall_by_load) begin
                de_state <= 3'b010;
            end else begin
                de_state <= 3'b001;
            end

            if (de_state.READY) begin
                de_pc <= if_pc;
            end else if (!ex_state.STALL) begin
                de_pc <= 32'h0;
            end
        end
    end

    /* -------------------------------- *
     * Stage 3: EX (execution)          *
     * -------------------------------- */

    state ex_state;
    logic [31:0] ex_pc;
    inst ex_inst;
    wire ex_stall_by_load;
    wire ex_invalid_by_jmp;

    logic [4:0] ex_rd_num;
    logic [11:0] ex_csr_num;

    logic [31:0] ex_rs1;
    logic [31:0] ex_rs2;
    logic [31:0] ex_imm;

    logic [4:0] ex_csr_zimm;
    logic [31:0] ex_csr;

    wire [31:0] ex_alu_rslt;

    riscoffee_alu alu (
        .RST_N(RST_N),
        .CLK  (CLK),

        .INST(de_inst),

        .RS1(de_rs1),
        .RS2(de_rs2),
        .PC (de_pc),
        .IMM(de_imm),

        .RSLT(ex_alu_rslt)
    );

    assign ex_stall_by_load  = ex_state.READY & (de_inst.LB | de_inst.LH | de_inst.LW | de_inst.LBU | de_inst.LHU) & de_state.READY & (de_rd_num == if_rs1_num | de_rd_num == if_rs2_num);
    assign ex_invalid_by_jmp = ex_state.READY & de_inst.UPDATE_PC;

    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            ex_state    <= 3'b100;
            ex_pc       <= 32'h0;

            ex_rs1      <= 32'h0;
            ex_rs2      <= 32'h0;
            ex_imm      <= 32'h0;

            ex_csr_zimm <= 5'h0;
            ex_csr      <= 32'h0;

            ex_rd_num   <= 5'h0;
            ex_csr_num  <= 12'h0;
        end else begin
            if (de_state.INVALID | ex_invalid_by_jmp) begin
                ex_state <= 3'b100;
            end else if (ex_stall_by_load) begin
                ex_state <= 3'b010;
            end else begin
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
            end else if (!ma_state.STALL) begin
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

    /* -------------------------------- *
     * Stage 4: MA (memory access)      *
     * -------------------------------- */

    state ma_state;
    inst ma_inst;

    logic [31:0] ma_alu_rslt;

    wire [31:0] ma_ram_dout;

    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            ma_state    <= 3'b100;
            ma_alu_rslt <= 32'h0;

            ma_rd_num   <= 5'h0;
            ma_csr_num  <= 12'h0;
        end else begin
            if (ex_state.INVALID | (!ma_state.STALL & ex_state.STALL)) begin
                ma_state <= 3'b100;
            end else begin
                ma_state <= 3'b001;
            end

            if (ma_state.READY) begin
                ma_inst     <= ex_inst;
                ma_alu_rslt <= ex_alu_rslt;

                ma_rd_num   <= ex_rd_num;
                ma_csr_num  <= ex_csr_num;
            end else if (!wb_state.STALL) begin
                ma_inst     <= 0;
                ma_alu_rslt <= 32'h0;

                ma_rd_num   <= 5'h0;
                ma_csr_num  <= 12'h0;
            end
        end
    end

    rip_memory memory (
        .clk(CLK),

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

    state wb_state;

    logic [4:0] ma_rd_num;
    logic [11:0] ma_csr_num;

    wire [31:0] wb_wdata;
    wire [31:0] wb_csr_data_in;
    wire [31:0] wb_csr_data_out;

    wire wb_reg_wen;
    wire wb_csr_write;
    wire wb_csr_set;
    wire wb_csr_clear;
    wire [11:0] csr_addr;

    assign wb_wdata       = (ma_inst.LB | ma_inst.LH | ma_inst.LW | ma_inst.LBU | ma_inst.LHU) ? ma_ram_dout : ma_alu_rslt;
    assign wb_csr_data_in = 32'h0;
    assign wb_reg_wen     = wb_state.READY && ma_inst.UPDATE_REG;
    assign csr_addr       = ma_inst.CSRRW | ma_inst.CSRRS | ma_inst.CSRRC | ma_inst.CSRRWI | ma_inst.CSRRSI | ma_inst.CSRRCI ? ma_csr_num : if_csr_num;

    riscoffee_regfile regfile (
        .RST_N(RST_N),
        .CLK  (CLK),

        .MA_RD_NUM(ma_rd_num),
        .WEN(wb_reg_wen),
        .WDATA(wb_wdata),

        .IF_RS1_NUM(if_rs1_num),
        .IF_RS2_NUM(if_rs2_num),

        .RS1(de_rs1_reg),
        .RS2(de_rs2_reg)
    );

    riscoffee_csr csr (
        .RST_N(RST_N),
        .CLK  (CLK),

        .WRITE(1'b0),
        .SET(1'b0),
        .CLEAR(1'b0),
        .CSR_ADDR(csr_addr),
        .CSR_DATA_IN(wb_csr_data_in),
        .CSR_DATA_OUT(wb_csr_data_out)
    );

    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            wb_state <= 3'b100;
        end else begin
            if (ma_state.INVALID) begin
                wb_state <= 3'b100;
            end else begin
                wb_state <= 3'b001;
            end
        end
    end

`ifdef VERILATOR
    integer file_handle, t;
    logic after_wb_ready;
    inst  wb_inst;
    logic [31:0] de_inst_code, ex_inst_code, ma_inst_code, wb_inst_code;

    initial begin
        file_handle = $fopen("dump.txt");
        t           = 0;
    end

    always_ff @(posedge CLK) begin
        assert (!(pc_state.READY & if_state.STALL));
        assert (!(if_state.READY & de_state.STALL));
        assert (!(de_state.READY & ex_state.STALL));
        assert (!(ex_state.READY & ma_state.STALL));
        assert (!(ma_state.READY & wb_state.STALL));
    end

    always_ff @(posedge CLK) begin
        t = t + 10;

        if (!RST_N) begin
            after_wb_ready <= 1'b0;
            de_inst_code   <= 32'h0;
            ex_inst_code   <= 32'h0;
            ma_inst_code   <= 32'h0;
            wb_inst_code   <= 32'h0;
        end else begin
            after_wb_ready <= wb_state.READY;
            if (de_state.READY) de_inst_code <= if_inst_code;
            if (ex_state.READY) ex_inst_code <= de_inst_code;
            if (ma_state.READY) ma_inst_code <= ex_inst_code;
            if (wb_state.READY) begin
                wb_inst      <= ma_inst;
                wb_inst_code <= ma_inst_code;
            end
        end

        if (after_wb_ready) begin
            $fdisplay(file_handle, "Inst: (%d ps)\n???  := %b(BIN) = %X (HEX LE)", t, wb_inst_code, wb_inst_code);
            $fdisplay(file_handle, "Regs after:");
            $fdisplay(file_handle, "x0 (zero):= %X, x1 ( ra ):= %X, x2 ( sp ):= %X, x3 ( gp ):= %X, ", regfile.regfile[0], regfile.regfile[1], regfile.regfile[2], regfile.regfile[3]);
            $fdisplay(file_handle, "x4 ( tp ):= %X, x5 ( t0 ):= %X, x6 ( t1 ):= %X, x7 ( t2 ):= %X, ", regfile.regfile[4], regfile.regfile[5], regfile.regfile[6], regfile.regfile[7]);
            $fdisplay(file_handle, "x8 ( s0 ):= %X, x9 ( s1 ):= %X, xa ( a0 ):= %X, xb ( a1 ):= %X, ", regfile.regfile[8], regfile.regfile[9], regfile.regfile[10], regfile.regfile[11]);
            $fdisplay(file_handle, "xc ( a2 ):= %X, xd ( a3 ):= %X, xe ( a4 ):= %X, xf ( a5 ):= %X, ", regfile.regfile[12], regfile.regfile[13], regfile.regfile[14], regfile.regfile[15]);
            $fdisplay(file_handle, "x10( a6 ):= %X, x11( a7 ):= %X, x12( s2 ):= %X, x13( s3 ):= %X, ", regfile.regfile[16], regfile.regfile[17], regfile.regfile[18], regfile.regfile[19]);
            $fdisplay(file_handle, "x14( s4 ):= %X, x15( s5 ):= %X, x16( s6 ):= %X, x17( s7 ):= %X, ", regfile.regfile[20], regfile.regfile[21], regfile.regfile[22], regfile.regfile[23]);
            $fdisplay(file_handle, "x18( s8 ):= %X, x19( s9 ):= %X, x1a( s10):= %X, x1b( s11):= %X, ", regfile.regfile[24], regfile.regfile[25], regfile.regfile[26], regfile.regfile[27]);
            $fdisplay(file_handle, "x1c( t3 ):= %X, x1d( t4 ):= %X, x1e( t5 ):= %X, x1f( t6 ):= %X,\n", regfile.regfile[28], regfile.regfile[29], regfile.regfile[30], regfile.regfile[31]);

            // finish simulation when invalid instruction is executed
            if (wb_state.READY & !|wb_inst) begin
                $fclose(file_handle);
                $finish;
            end
        end
    end
`endif
endmodule

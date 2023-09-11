`default_nettype none
`timescale 1ns / 1ps

// `include "decode.sv"
// `include "regfile.sv"
// `include "csr.sv"
// `include "alu.sv"
// `include "ram.sv"

module riscoffee_core (
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
        if (ma_state.READY & (ex_inst.BEQ | ex_inst.BNE | ex_inst.BLT | ex_inst.BGE | ex_inst.BLTU | ex_inst.BGEU | ex_inst.JAL | ex_inst.JALR)) begin
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
            pc       <= 32'h0 - 32'h4;
        end else begin
            if (if_stall_by_mem) begin
                pc_state <= 3'b010;
            end else begin
                pc_state <= 3'b001;
            end

            if (pc_state.READY) begin
                pc <= pc_next;
            end
        end
    end

    /* -------------------------------- *
     * Stage 1: IF (instruction fetch)  *
     * -------------------------------- */

    state if_state;
    logic [31:0] if_pc;
    wire [31:0] if_inst_code;
    wire if_stall_by_mem;

    wire [4:0] if_rs1_num;
    wire [4:0] if_rs2_num;
    wire [4:0] if_rd_num;
    wire [11:0] if_csr_num;

    assign if_inst_code    = ma_ram_dout;
    assign if_stall_by_mem = ex_state.READY & de_inst.ACCESS_MEM;

    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            if_state <= 3'b100;
            if_pc    <= 32'h0;
        end else begin
            if (pc_state.INVALID | ex_invalid_by_jmp) begin
                if_state <= 3'b100;
            end else if (if_stall_by_mem) begin
                if_state <= 3'b010;
            end else begin
                if_state <= 3'b001;
            end

            if (if_state.READY) begin
                if_pc <= pc;
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
        .CLK  (CLK),
        .READY(de_state.READY),

        .INST_CODE(if_inst_code),

        .RS1_NUM(if_rs1_num),
        .RS2_NUM(if_rs2_num),
        .RD_NUM (if_rd_num),

        .CSR_NUM (if_csr_num),
        .CSR_ZIMM(de_csr_zimm),

        .IMM(de_imm),

        .INST(de_inst)
    );

    always_comb begin
        if (ma_state.READY && ex_rd_num != 5'h0 && de_rs1_num == ex_rd_num) begin
            de_rs1 = ex_alu_rslt;
        end else if (wb_state.READY && ma_rd_num != 5'h0 && de_rs1_num == ma_rd_num) begin
            de_rs1 = ma_alu_rslt;
        end else begin
            de_rs1 = de_rs1_reg;
        end

        if (ma_state.READY && ex_rd_num != 5'h0 && de_rs2_num == ex_rd_num) begin
            de_rs2 = ex_alu_rslt;
        end else if (wb_state.READY && ma_rd_num != 5'h0 && de_rs2_num == ma_rd_num) begin
            de_rs2 = ma_alu_rslt;
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
            if (if_state.INVALID | (de_state.READY & if_state.STALL) | ex_invalid_by_jmp) begin
                de_state <= 3'b100;
            end else begin
                de_state <= 3'b001;
            end

            if (de_state.READY) begin
                de_pc      <= if_pc;

                de_rs1_num <= if_rs1_num;
                de_rs2_num <= if_rs2_num;
                de_rd_num  <= if_rd_num;
                de_csr_num <= if_csr_num;
            end
        end
    end

    /* -------------------------------- *
     * Stage 3: EX (execution)          *
     * -------------------------------- */

    state ex_state;
    logic [31:0] ex_pc;
    inst ex_inst;
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
            if (ex_state.INVALID) begin
                ma_state <= 3'b100;
            end else begin
                ma_state <= 3'b001;
            end

            if (ma_state.READY) begin
                ma_inst     <= ex_inst;
                ma_alu_rslt <= ex_alu_rslt;

                ma_rd_num   <= ex_rd_num;
                ma_csr_num  <= ex_csr_num;
            end
        end
    end

    riscoffee_ram ram (
        .CLK(CLK),
        .WEN(ma_state.READY),

        .INST(ex_inst),

        .PC  (pc),
        .ADDR(ex_alu_rslt),
        .DIN (ex_rs2),
        .DOUT(ma_ram_dout)
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

    assign wb_wdata       = ma_alu_rslt;
    assign wb_csr_data_in = 32'h0;
    assign wb_reg_wen     = wb_state.READY && (ma_rd_num != 5'h0);
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
endmodule

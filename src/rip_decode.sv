`default_nettype none
`timescale 1ns / 1ps

module rip_decode
    import rip_type::*;
#(
    parameter int REG_ADDR_WIDTH = 5,
    parameter int CSR_ADDR_WIDTH = 12
) (
    input rst_n,
    input clk,

    input de_ready,
    input ex_stall,

    // instruction code
    input [31:0] inst_code,

    // register number
    output wire  [REG_ADDR_WIDTH-1:0] if_rs1_num,
    output wire  [REG_ADDR_WIDTH-1:0] if_rs2_num,
    output wire  [REG_ADDR_WIDTH-1:0] if_rd_num,
    output logic [REG_ADDR_WIDTH-1:0] de_rs1_num,
    output logic [REG_ADDR_WIDTH-1:0] de_rs2_num,
    output logic [REG_ADDR_WIDTH-1:0] de_rd_num,

    // csr number
    output wire  [CSR_ADDR_WIDTH-1:0] if_csr_num,
    output wire  [CSR_ADDR_WIDTH-1:0] de_csr_num,
    output logic [REG_ADDR_WIDTH-1:0] csr_zimm,

    // immediate
    output logic [31:0] imm,

    // instructions and pipeline control
    output inst_t inst
);

    // instruction type and immediate
    wire r_type, i_type, s_type, b_type, u_type, j_type;
    wire csr_type, csr_i_type;

    assign r_type = inst_code[6:5] == 2'b01 && inst_code[4:2] == 3'b100;
    assign i_type = (inst_code[6:5] == 2'b00 &&
                     (inst_code[4:2] == 3'b000 || inst_code[4:2] == 3'b100)) ||
        (inst_code[6:5] == 2'b11 && inst_code[4:2] == 3'b001);
    assign s_type = inst_code[6:5] == 2'b01 && inst_code[4:2] == 3'b000;
    assign b_type = inst_code[6:5] == 2'b11 && inst_code[4:2] == 3'b000;
    assign
        u_type = (inst_code[6:5] == 2'b00 || inst_code[6:5] == 2'b01) && inst_code[4:2] == 3'b101;
    assign j_type = inst_code[6:5] == 2'b11 && inst_code[4:2] == 3'b011;
    // The following two types are classified as I-type but are treated as two different types for convenience.
    assign csr_type = inst_code[6:5] == 2'b11 && inst_code[4:2] == 3'b100 && !inst_code[14];
    assign csr_i_type = inst_code[6:5] == 2'b11 && inst_code[4:2] == 3'b100 && inst_code[14];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            imm <= 32'h0;
        end
        else if (de_ready) begin
            if (i_type) begin
                if (funct3 == 3'b101 && inst_code[4:2] == 3'b100) begin
                    imm <= {27'b0, inst_code[24:20]};
                end
                else begin
                    imm <= {{20{inst_code[31]}}, inst_code[31:20]};
                end
            end
            else if (s_type) begin
                imm <= {{20{inst_code[31]}}, inst_code[31:25], inst_code[11:7]};
            end
            else if (b_type) begin
                imm <= {
                    {19{inst_code[31]}},
                    inst_code[31],
                    inst_code[7],
                    inst_code[30:25],
                    inst_code[11:8],
                    1'b0
                };
            end
            else if (u_type) begin
                imm <= {inst_code[31:12], 12'b0};
            end
            else if (j_type) begin
                imm <= {
                    {11{inst_code[31]}},
                    inst_code[31],
                    inst_code[19:12],
                    inst_code[20],
                    inst_code[30:21],
                    1'b0
                };
            end
            else begin
                imm <= 32'h0;
            end
        end
        else if (!ex_stall) begin
            imm <= 32'h0;
        end
    end

    // register number
    assign if_rd_num = (r_type | i_type | u_type | j_type | csr_type | csr_i_type) ?
        inst_code[11:7] : 5'b0;
    assign if_rs1_num = (r_type | i_type | s_type | b_type | csr_type) ? inst_code[19:15] : 5'b0;
    assign if_rs2_num = (r_type | s_type | b_type) ? inst_code[24:20] : 5'b0;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            de_rd_num  <= 5'b0;
            de_rs1_num <= 5'b0;
            de_rs2_num <= 5'b0;
        end
        else if (de_ready) begin
            de_rd_num  <= if_rd_num;
            de_rs1_num <= if_rs1_num;
            de_rs2_num <= if_rs2_num;
        end
        else if (!ex_stall) begin
            de_rd_num  <= 5'b0;
            de_rs1_num <= 5'b0;
            de_rs2_num <= 5'b0;
        end
    end

    // csr number
    assign if_csr_num = de_ready & (csr_type | csr_i_type) ? inst_code[31:20] : 12'b0;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            de_csr_num <= 12'b0;
            csr_zimm   <= 5'b0;
        end
        else if (de_ready) begin
            de_csr_num <= if_csr_num;
            csr_zimm   <= csr_i_type ? inst_code[19:15] : 5'b0;
        end
        else if (!ex_stall) begin
            de_csr_num <= 12'b0;
            csr_zimm   <= 5'b0;
        end
    end

    // function code
    wire [6:0] funct7;
    wire [2:0] funct3;
    wire [11:0] funct12;
    assign funct7  = inst_code[31:25];
    assign funct3  = inst_code[14:12];
    assign funct12 = inst_code[31:20];

    // instruction
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            inst <= 0;
        end
        else if (de_ready) begin
            // RV32I instruction
            inst.LUI <= inst_code[6:0] == 7'b0110111;
            inst.AUIPC <= inst_code[6:0] == 7'b0010111;
            inst.JAL <= inst_code[6:0] == 7'b1101111;
            inst.JALR <= inst_code[6:0] == 7'b1100111;
            inst.BEQ <= inst_code[6:0] == 7'b1100011 && funct3 == 3'b000;
            inst.BNE <= inst_code[6:0] == 7'b1100011 && funct3 == 3'b001;
            inst.BLT <= inst_code[6:0] == 7'b1100011 && funct3 == 3'b100;
            inst.BGE <= inst_code[6:0] == 7'b1100011 && funct3 == 3'b101;
            inst.BLTU <= inst_code[6:0] == 7'b1100011 && funct3 == 3'b110;
            inst.BGEU <= inst_code[6:0] == 7'b1100011 && funct3 == 3'b111;
            inst.LB <= inst_code[6:0] == 7'b0000011 && funct3 == 3'b000;
            inst.LH <= inst_code[6:0] == 7'b0000011 && funct3 == 3'b001;
            inst.LW <= inst_code[6:0] == 7'b0000011 && funct3 == 3'b010;
            inst.LBU <= inst_code[6:0] == 7'b0000011 && funct3 == 3'b100;
            inst.LHU <= inst_code[6:0] == 7'b0000011 && funct3 == 3'b101;
            inst.SB <= inst_code[6:0] == 7'b0100011 && funct3 == 3'b000;
            inst.SH <= inst_code[6:0] == 7'b0100011 && funct3 == 3'b001;
            inst.SW <= inst_code[6:0] == 7'b0100011 && funct3 == 3'b010;
            inst.ADDI <= inst_code[6:0] == 7'b0010011 && funct3 == 3'b000;
            inst.SLTI <= inst_code[6:0] == 7'b0010011 && funct3 == 3'b010;
            inst.SLTIU <= inst_code[6:0] == 7'b0010011 && funct3 == 3'b011;
            inst.XORI <= inst_code[6:0] == 7'b0010011 && funct3 == 3'b100;
            inst.ORI <= inst_code[6:0] == 7'b0010011 && funct3 == 3'b110;
            inst.ANDI <= inst_code[6:0] == 7'b0010011 && funct3 == 3'b111;
            inst.SLLI <= inst_code[6:0] == 7'b0010011 && funct3 == 3'b001 && funct7 == 7'b0000000;
            inst.SRLI <= inst_code[6:0] == 7'b0010011 && funct3 == 3'b101 && funct7 == 7'b0000000;
            inst.SRAI <= inst_code[6:0] == 7'b0010011 && funct3 == 3'b101 && funct7 == 7'b0100000;
            inst.ADD <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0000000;
            inst.SUB <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0100000;
            inst.SLL <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b001 && funct7 == 7'b0000000;
            inst.SLT <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b010 && funct7 == 7'b0000000;
            inst.SLTU <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b011 && funct7 == 7'b0000000;
            inst.XOR <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b100 && funct7 == 7'b0000000;
            inst.SRL <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b101 && funct7 == 7'b0000000;
            inst.SRA <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b101 && funct7 == 7'b0100000;
            inst.OR <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b110 && funct7 == 7'b0000000;
            inst.AND <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b111 && funct7 == 7'b0000000;
            inst.FENCE <= inst_code[6:0] == 7'b0001111 && funct3 == 3'b000;
            inst.FENCE_I <= inst_code[6:0] == 7'b0001111 && funct3 == 3'b001;
            inst.ECALL <= inst_code[6:0] == 7'b1110011 && funct3 == 3'b000 && funct12 == 12'h0;
            inst.EBREAK <= inst_code[6:0] == 7'b1110011 && funct3 == 3'b000 && funct12 == 12'h1;
            inst.MRET <= inst_code[6:0] == 7'b1110011 && funct3 == 3'b000 && funct12 == 12'h302;
            inst.CSRRW <= inst_code[6:0] == 7'b1110011 && funct3 == 3'b001;
            inst.CSRRS <= inst_code[6:0] == 7'b1110011 && funct3 == 3'b010;
            inst.CSRRC <= inst_code[6:0] == 7'b1110011 && funct3 == 3'b011;
            inst.CSRRWI <= inst_code[6:0] == 7'b1110011 && funct3 == 3'b101;
            inst.CSRRSI <= inst_code[6:0] == 7'b1110011 && funct3 == 3'b110;
            inst.CSRRCI <= inst_code[6:0] == 7'b1110011 && funct3 == 3'b111;

            // RV32M instruction
            inst.MUL <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0000001;
            inst.MULH <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b001 && funct7 == 7'b0000001;
            inst.MULHSU <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b010 && funct7 == 7'b0000001;
            inst.MULHU <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b011 && funct7 == 7'b0000001;
            inst.DIV <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b100 && funct7 == 7'b0000001;
            inst.DIVU <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b101 && funct7 == 7'b0000001;
            inst.REM <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b110 && funct7 == 7'b0000001;
            inst.REMU <= inst_code[6:0] == 7'b0110011 && funct3 == 3'b111 && funct7 == 7'b0000001;

            // Custom instruction
            inst.EXTX <= inst_code[6:0] == 7'b0001011 && funct12 == 12'h0;
            inst.EXT <= inst_code[6:0] == 7'b0001011 && funct12 == 12'h1;

            // pipeline control
            inst.ACCESS_MEM <= inst_code[6:0] == 7'b0000011  /* LOAD */ ||
                inst_code[6:0] == 7'b0100011  /* STORE */;
            inst.UPDATE_REG <= if_rd_num != 5'h0;
            inst.UPDATE_CSR <= inst_code[6:0] == 7'b1110011 && funct3 != 3'b000;
            inst.UPDATE_PC <= inst_code[6:0] == 7'b1101111  /* JAL */ || inst_code[6:0] ==
                7'b1100111  /* JALR */ || inst_code[6:0] == 7'b1100011  /* BRANCH */ ||
                (inst_code[6:0] == 7'b1110011 && funct3 == 3'b000)  /* ECALL and EBREAK */;
        end
        else if (!ex_stall) begin
            inst <= 0;
        end
    end
endmodule : rip_decode

`default_nettype none
`timescale 1ns / 1ps

module riscoffee_decode (
    input RST_N,
    input CLK,
    input READY,

    // instruction code
    input [31:0] INST_CODE,

    // register number
    output wire [4:0] RS1_NUM,
    output wire [4:0] RS2_NUM,
    output wire [4:0] RD_NUM,

    // csr number
    output wire  [11:0] CSR_NUM,
    output logic [ 4:0] CSR_ZIMM,

    // immediate
    output logic [31:0] IMM,

    // instructions and pipeline control
    output inst INST
);

    // instruction type and immediate
    wire r_type, i_type, s_type, b_type, u_type, j_type;
    wire csr_type, csr_i_type;

    assign r_type = INST_CODE[6:5] == 2'b01 && INST_CODE[4:2] == 3'b100;
    assign i_type = (INST_CODE[6:5] == 2'b00 && (INST_CODE[4:2] == 3'b000 || INST_CODE[4:2] == 3'b100)) || (INST_CODE[6:5] == 2'b11 && INST_CODE[4:2] == 3'b001);
    assign s_type = INST_CODE[6:5] == 2'b01 && INST_CODE[4:2] == 3'b000;
    assign b_type = INST_CODE[6:5] == 2'b11 && INST_CODE[4:2] == 3'b000;
    assign u_type = (INST_CODE[6:5] == 2'b00 || INST_CODE[6:5] == 2'b01) && INST_CODE[4:2] == 3'b101;
    assign j_type = INST_CODE[6:5] == 2'b11 && INST_CODE[4:2] == 3'b011;
    // The following two types are classified as I-type but are treated as two different types for convenience.
    assign csr_type = INST_CODE[6:5] == 2'b11 && INST_CODE[4:2] == 3'b100 && !INST_CODE[14];
    assign csr_i_type = INST_CODE[6:5] == 2'b11 && INST_CODE[4:2] == 3'b100 && INST_CODE[14];

    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            IMM <= 32'h0;
        end else if (READY) begin
            if (i_type) begin
                if (funct3 == 3'b101 && INST_CODE[4:2] == 3'b100) begin
                    IMM <= {27'b0, INST_CODE[24:20]};
                end else begin
                    IMM <= {{20{INST_CODE[31]}}, INST_CODE[31:20]};
                end
            end else if (s_type) begin
                IMM <= {{20{INST_CODE[31]}}, INST_CODE[31:25], INST_CODE[11:7]};
            end else if (b_type) begin
                IMM <= {{19{INST_CODE[31]}}, INST_CODE[31], INST_CODE[7], INST_CODE[30:25], INST_CODE[11:8], 1'b0};
            end else if (u_type) begin
                IMM <= {INST_CODE[31:12], 12'b0};
            end else if (j_type) begin
                IMM <= {{11{INST_CODE[31]}}, INST_CODE[31], INST_CODE[19:12], INST_CODE[20], INST_CODE[30:21], 1'b0};
            end else begin
                IMM <= 32'h0;
            end
        end else begin
            IMM <= 32'h0;
        end
    end

    // register number
    assign RD_NUM  = READY & (r_type | i_type | u_type | j_type | csr_type | csr_i_type) ? INST_CODE[11:7] : 5'b0;
    assign RS1_NUM = READY & (r_type | i_type | s_type | b_type | csr_type) ? INST_CODE[19:15] : 5'b0;
    assign RS2_NUM = READY & (r_type | s_type | b_type) ? INST_CODE[24:20] : 5'b0;

    // csr number
    assign CSR_NUM = READY & (csr_type | csr_i_type) ? INST_CODE[31:20] : 12'b0;
    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            CSR_ZIMM <= 5'b0;
        end else if (READY) begin
            if (csr_i_type) begin
                CSR_ZIMM <= INST_CODE[19:15];
            end else begin
                CSR_ZIMM <= 5'b0;
            end
        end else begin
            CSR_ZIMM <= 5'b0;
        end
    end

    // function code
    wire [6:0] funct7;
    wire [2:0] funct3;
    assign funct7 = INST_CODE[31:25];
    assign funct3 = INST_CODE[14:12];

    // instruction
    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            INST <= 0;
        end else if (READY) begin
            // RV32I instruction
            INST.LUI        <= INST_CODE[6:0] == 7'b0110111;
            INST.AUIPC      <= INST_CODE[6:0] == 7'b0010111;
            INST.JAL        <= INST_CODE[6:0] == 7'b1101111;
            INST.JALR       <= INST_CODE[6:0] == 7'b1100111;
            INST.BEQ        <= INST_CODE[6:0] == 7'b1100011 && funct3 == 3'b000;
            INST.BNE        <= INST_CODE[6:0] == 7'b1100011 && funct3 == 3'b001;
            INST.BLT        <= INST_CODE[6:0] == 7'b1100011 && funct3 == 3'b100;
            INST.BGE        <= INST_CODE[6:0] == 7'b1100011 && funct3 == 3'b101;
            INST.BLTU       <= INST_CODE[6:0] == 7'b1100011 && funct3 == 3'b110;
            INST.BGEU       <= INST_CODE[6:0] == 7'b1100011 && funct3 == 3'b111;
            INST.LB         <= INST_CODE[6:0] == 7'b0000011 && funct3 == 3'b000;
            INST.LH         <= INST_CODE[6:0] == 7'b0000011 && funct3 == 3'b001;
            INST.LW         <= INST_CODE[6:0] == 7'b0000011 && funct3 == 3'b010;
            INST.LBU        <= INST_CODE[6:0] == 7'b0000011 && funct3 == 3'b100;
            INST.LHU        <= INST_CODE[6:0] == 7'b0000011 && funct3 == 3'b101;
            INST.SB         <= INST_CODE[6:0] == 7'b0100011 && funct3 == 3'b000;
            INST.SH         <= INST_CODE[6:0] == 7'b0100011 && funct3 == 3'b001;
            INST.SW         <= INST_CODE[6:0] == 7'b0100011 && funct3 == 3'b010;
            INST.ADDI       <= INST_CODE[6:0] == 7'b0010011 && funct3 == 3'b000;
            INST.SLTI       <= INST_CODE[6:0] == 7'b0010011 && funct3 == 3'b010;
            INST.SLTIU      <= INST_CODE[6:0] == 7'b0010011 && funct3 == 3'b011;
            INST.XORI       <= INST_CODE[6:0] == 7'b0010011 && funct3 == 3'b100;
            INST.ORI        <= INST_CODE[6:0] == 7'b0010011 && funct3 == 3'b110;
            INST.ANDI       <= INST_CODE[6:0] == 7'b0010011 && funct3 == 3'b111;
            INST.SLLI       <= INST_CODE[6:0] == 7'b0010011 && funct3 == 3'b001 && funct7 == 7'b0000000;
            INST.SRLI       <= INST_CODE[6:0] == 7'b0010011 && funct3 == 3'b101 && funct7 == 7'b0000000;
            INST.SRAI       <= INST_CODE[6:0] == 7'b0010011 && funct3 == 3'b101 && funct7 == 7'b0100000;
            INST.ADD        <= INST_CODE[6:0] == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0000000;
            INST.SUB        <= INST_CODE[6:0] == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0100000;
            INST.SLL        <= INST_CODE[6:0] == 7'b0110011 && funct3 == 3'b001 && funct7 == 7'b0000000;
            INST.SLT        <= INST_CODE[6:0] == 7'b0110011 && funct3 == 3'b010 && funct7 == 7'b0000000;
            INST.SLTU       <= INST_CODE[6:0] == 7'b0110011 && funct3 == 3'b011 && funct7 == 7'b0000000;
            INST.XOR        <= INST_CODE[6:0] == 7'b0110011 && funct3 == 3'b100 && funct7 == 7'b0000000;
            INST.SRL        <= INST_CODE[6:0] == 7'b0110011 && funct3 == 3'b101 && funct7 == 7'b0000000;
            INST.SRA        <= INST_CODE[6:0] == 7'b0110011 && funct3 == 3'b101 && funct7 == 7'b0100000;
            INST.OR         <= INST_CODE[6:0] == 7'b0110011 && funct3 == 3'b110 && funct7 == 7'b0000000;
            INST.AND        <= INST_CODE[6:0] == 7'b0110011 && funct3 == 3'b111 && funct7 == 7'b0000000;
            INST.FENCE      <= INST_CODE[6:0] == 7'b0001111 && funct3 == 3'b000;
            INST.FENCE_I    <= INST_CODE[6:0] == 7'b0001111 && funct3 == 3'b001;
            INST.ECALL      <= INST_CODE[6:0] == 7'b1110011 && funct3 == 3'b000 && INST_CODE[31:20] == 12'b000000000000;
            INST.EBREAK     <= INST_CODE[6:0] == 7'b1110011 && funct3 == 3'b000 && INST_CODE[31:20] == 12'b000000000001;
            INST.CSRRW      <= INST_CODE[6:0] == 7'b1110011 && funct3 == 3'b001;
            INST.CSRRS      <= INST_CODE[6:0] == 7'b1110011 && funct3 == 3'b010;
            INST.CSRRC      <= INST_CODE[6:0] == 7'b1110011 && funct3 == 3'b011;
            INST.CSRRWI     <= INST_CODE[6:0] == 7'b1110011 && funct3 == 3'b101;
            INST.CSRRSI     <= INST_CODE[6:0] == 7'b1110011 && funct3 == 3'b110;
            INST.CSRRCI     <= INST_CODE[6:0] == 7'b1110011 && funct3 == 3'b111;

            // pipeline control
            INST.ACCESS_MEM <= INST_CODE[6:0] == 7'b0000011 /* LOAD */ || INST_CODE[6:0] == 7'b0100011 /* STORE */;
            INST.UPDATE_REG <= RD_NUM != 5'h0;
            INST.UPDATE_PC  <= INST_CODE[6:0] == 7'b1101111 /* JAL */ || INST_CODE[6:0] == 7'b1100111 /* JALR */ || INST_CODE[6:0] == 7'b1100011 /* BRANCH */ || (INST_CODE[6:0] == 7'b1110011 && funct3 == 3'b000) /* ECALL and EBREAK */;
        end else begin
            INST <= 0;
        end
    end
endmodule

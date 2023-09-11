`default_nettype none
`timescale 1ns / 1ps

module riscoffee_alu (
    input RST_N,
    input CLK,

    input inst INST,

    input [31:0] RS1,
    input [31:0] RS2,
    input [31:0] PC,
    input [31:0] IMM,

    output reg [31:0] RSLT
);
    logic [31:0] a;
    logic [31:0] b;
    logic [4:0] shamt;
    // assign a     = (INST.AUIPC | INST.JAL | INST.JALR) ? PC : RS1;
    // assign b     = (INST.LUI | INST.AUIPC | INST.JAL | INST.JALR | INST.LB | INST.LH | INST.LW | INST.LBU | INST.LHU | INST.SB | INST.SH | INST.SW | INST.ADDI | INST.SLTI | INST.SLTIU | INST.XORI | INST.ORI | INST.ANDI | INST.SLLI | INST.SRLI | INST.SRAI) ? IMM : RS2;
    // assign shamt = IMM[4:0];

    always_comb begin
        if (INST.AUIPC | INST.JAL | INST.JALR) begin
            a = PC;
        end else begin
            a = RS1;
        end

        if (INST.JAL | INST.JALR) begin
            b = 32'h4;
        end else if (INST.LUI | INST.AUIPC | INST.LB | INST.LH | INST.LW | INST.LBU | INST.LHU | INST.SB | INST.SH | INST.SW | INST.ADDI | INST.SLTI | INST.SLTIU | INST.XORI | INST.ORI | INST.ANDI | INST.SLLI | INST.SRLI | INST.SRAI) begin
            b = IMM;
        end else begin
            b = RS2;
        end
    end

    logic alu_eq;
    logic alu_ne;
    logic alu_lt;
    logic alu_ge;
    logic alu_ltu;
    logic alu_geu;
    logic [31:0] alu_add_sub;
    logic [31:0] alu_sll;
    logic [31:0] alu_xor;
    logic [31:0] alu_srl;
    logic [31:0] alu_sra;
    logic [31:0] alu_or;
    logic [31:0] alu_and;

    always_comb begin
        alu_eq      = a == b;
        alu_ne      = a != b;
        alu_lt      = $signed(a) < $signed(b);
        alu_ge      = $signed(a) >= $signed(b);
        alu_ltu     = a < b;
        alu_geu     = a >= b;
        alu_add_sub = INST.SUB ? a - b : a + b;
        alu_sll     = a << shamt;
        alu_xor     = a ^ b;
        alu_srl     = a >> shamt;
        alu_sra     = $signed(a) >>> shamt;
        alu_or      = a | b;
        alu_and     = a & b;
    end

    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            RSLT <= 0;
        end else begin
            if (INST.BEQ) begin
                RSLT <= {31'b0, alu_eq};
            end else if (INST.BNE) begin
                RSLT <= {31'b0, alu_ne};
            end else if (INST.BLT | INST.SLT | INST.SLTI) begin
                RSLT <= {31'b0, alu_lt};
            end else if (INST.BGE) begin
                RSLT <= {31'b0, alu_ge};
            end else if (INST.BLTU | INST.SLTU | INST.SLTIU) begin
                RSLT <= {31'b0, alu_ltu};
            end else if (INST.BGEU) begin
                RSLT <= {31'b0, alu_geu};
            end else if (INST.LUI | INST.AUIPC | INST.JAL | INST.JALR | INST.LB | INST.LH | INST.LW | INST.LBU | INST.LHU | INST.SB | INST.SH | INST.SW | INST.ADDI | INST.ADD | INST.SUB) begin
                RSLT <= alu_add_sub;
            end else if (INST.SLL | INST.SLLI) begin
                RSLT <= alu_sll;
            end else if (INST.XOR | INST.XORI) begin
                RSLT <= alu_xor;
            end else if (INST.SRL | INST.SRLI) begin
                RSLT <= alu_srl;
            end else if (INST.SRA | INST.SRAI) begin
                RSLT <= alu_sra;
            end else if (INST.OR | INST.ORI) begin
                RSLT <= alu_or;
            end else if (INST.AND | INST.ANDI) begin
                RSLT <= alu_and;
            end else begin
                RSLT <= 0;
            end
        end
    end
endmodule

`default_nettype none
`timescale 1ns / 1ps

module rip_alu
    import rip_type::*;
#(
    parameter int DATA_WIDTH  = 32,
    parameter int SHAMT_WIDTH = 5
) (
    input rst_n,
    input clk,
    input ex_ready,

    input inst_t inst,

    input [ DATA_WIDTH-1:0] rs1,
    input [ DATA_WIDTH-1:0] rs2,
    input [ DATA_WIDTH-1:0] pc,
    input [ DATA_WIDTH-1:0] csr,
    input [ DATA_WIDTH-1:0] imm,
    input [SHAMT_WIDTH-1:0] zimm,

    output reg [DATA_WIDTH-1:0] rslt
);
    logic [ DATA_WIDTH-1:0] a;
    logic [ DATA_WIDTH-1:0] b;
    logic [SHAMT_WIDTH-1:0] shamt;

    assign shamt = inst.SLL | inst.SRL | inst.SRA | inst.SLLI | inst.SRLI | inst.SRAI ?
        b[SHAMT_WIDTH-1:0] : 0;

    always_comb begin
        if (inst.AUIPC | inst.JAL | inst.JALR) begin
            a = pc;
        end
        else if (inst.CSRRWI | inst.CSRRSI | inst.CSRRCI) begin
            a = {27'b0, zimm};
        end
        else begin
            a = rs1;
        end

        if (inst.JAL | inst.JALR) begin
            b = 32'h4;
        end
        else if (inst.LUI | inst.AUIPC | inst.LB | inst.LH | inst.LW | inst.LBU | inst.LHU |
                 inst.SB | inst.SH | inst.SW | inst.ADDI | inst.SLTI | inst.SLTIU | inst.XORI |
                 inst.SLLI | inst.SRLI | inst.SRAI | inst.ORI | inst.ANDI) begin
            b = imm;
        end
        else if (inst.CSRRW | inst.CSRRS | inst.CSRRC | inst.CSRRWI | inst.CSRRSI |
                 inst.CSRRCI) begin
            b = csr;
        end
        else begin
            b = rs2;
        end
    end

    logic alu_eq;
    logic alu_ne;
    logic alu_lt;
    logic alu_ge;
    logic alu_ltu;
    logic alu_geu;
    logic [DATA_WIDTH-1:0] alu_add_sub;
    logic [DATA_WIDTH-1:0] alu_sll;
    logic [DATA_WIDTH-1:0] alu_xor;
    logic [DATA_WIDTH-1:0] alu_srl;
    logic [DATA_WIDTH-1:0] alu_sra;
    logic [DATA_WIDTH-1:0] alu_or;
    logic [DATA_WIDTH-1:0] alu_and;
    logic [DATA_WIDTH-1:0] alu_clear;
    logic [2*DATA_WIDTH-1:0] alu_mul_ss;
    logic [2*DATA_WIDTH-1:0] alu_mul_su;
    logic [2*DATA_WIDTH-1:0] alu_mul_uu;
    logic [DATA_WIDTH-1:0] alu_div_s;
    logic [DATA_WIDTH-1:0] alu_div_u;
    logic [DATA_WIDTH-1:0] alu_rem_s;
    logic [DATA_WIDTH-1:0] alu_rem_u;

    always_comb begin
        alu_eq      = a == b;
        alu_ne      = a != b;
        alu_lt      = $signed(a) < $signed(b);
        alu_ge      = $signed(a) >= $signed(b);
        alu_ltu     = a < b;
        alu_geu     = a >= b;
        alu_add_sub = inst.SUB ? a - b : a + b;
        alu_sll     = a << shamt;
        alu_xor     = a ^ b;
        alu_srl     = a >> shamt;
        alu_sra     = $signed(a) >>> shamt;
        alu_or      = a | b;
        alu_and     = a & b;
        alu_clear   = ~a & b;
        alu_mul_ss  = $signed(a) * $signed(b);
        alu_mul_su  = $signed(a) * $signed({32'h0, b});
        alu_mul_uu  = a * b;

        if (b == '0) begin
            alu_div_u = '1;
            alu_rem_u = a;
        end
        else begin
            alu_div_u = a / b;
            alu_rem_u = a % b;
        end

        if (b == '0) begin
            alu_div_s = '1;
            alu_rem_s = a;
        end
        else if (a == 32'h80000000 && b == 32'hFFFFFFFF) begin
            alu_div_s = 32'h80000000;
            alu_rem_s = 0;
        end
        else if ($signed(a) < $signed(0)) begin
            alu_div_s = -(-$signed(a) / $signed(b));
            alu_rem_s = -(-$signed(a) % $signed(b));
        end
        else begin
            alu_div_s = $signed(a) / $signed(b);
            alu_rem_s = $signed(a) % $signed(b);
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rslt <= 0;
        end
        else if (ex_ready) begin
            if (inst.BEQ) begin
                rslt <= {31'b0, alu_eq};
            end
            else if (inst.BNE) begin
                rslt <= {31'b0, alu_ne};
            end
            else if (inst.BLT | inst.SLT | inst.SLTI) begin
                rslt <= {31'b0, alu_lt};
            end
            else if (inst.BGE) begin
                rslt <= {31'b0, alu_ge};
            end
            else if (inst.BLTU | inst.SLTU | inst.SLTIU) begin
                rslt <= {31'b0, alu_ltu};
            end
            else if (inst.BGEU) begin
                rslt <= {31'b0, alu_geu};
            end
            else if (inst.LUI) begin
                rslt <= imm;
            end
            else if (inst.AUIPC | inst.JAL | inst.JALR | inst.LB | inst.LH | inst.LW | inst.LBU |
                     inst.LHU | inst.SB | inst.SH | inst.SW | inst.ADDI | inst.ADD | inst.SUB) begin
                rslt <= alu_add_sub;
            end
            else if (inst.SLL | inst.SLLI) begin
                rslt <= alu_sll;
            end
            else if (inst.XOR | inst.XORI) begin
                rslt <= alu_xor;
            end
            else if (inst.SRL | inst.SRLI) begin
                rslt <= alu_srl;
            end
            else if (inst.SRA | inst.SRAI) begin
                rslt <= alu_sra;
            end
            else if (inst.OR | inst.ORI | inst.CSRRS | inst.CSRRSI) begin
                rslt <= alu_or;
            end
            else if (inst.AND | inst.ANDI) begin
                rslt <= alu_and;
            end
            else if (inst.CSRRW | inst.CSRRWI) begin
                rslt <= a;
            end
            else if (inst.CSRRC | inst.CSRRCI) begin
                rslt <= alu_clear;
            end
            else if (inst.MUL) begin
                rslt <= alu_mul_uu[DATA_WIDTH-1:0];
            end
            else if (inst.MULH) begin
                rslt <= alu_mul_ss[63:32];
            end
            else if (inst.MULHSU) begin
                rslt <= alu_mul_su[63:32];
            end
            else if (inst.MULHU) begin
                rslt <= alu_mul_uu[63:32];
            end
            else if (inst.DIV) begin
                rslt <= alu_div_s;
            end
            else if (inst.DIVU) begin
                rslt <= alu_div_u;
            end
            else if (inst.REM) begin
                rslt <= alu_rem_s;
            end
            else if (inst.REMU) begin
                rslt <= alu_rem_u;
            end
            else begin
                rslt <= 0;
            end
        end
    end
endmodule : rip_alu

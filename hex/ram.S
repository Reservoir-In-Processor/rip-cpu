00  jal ra, 0x74
04  addi sp, sp, -32
08  sw ra, 28(sp)
0C  sw s0, 24(sp)
10  sw s1, 20(sp)
14  addi s0, sp, 32
18  sw a0, -20(s0)
1C  lw a4, -20(s0)
20  addi a5, zero, 1
24  blt a5, a4, 12
28  addi a5, zero, 1
2C  jal zero, 0x30
30  lw a5, -20(s0)
34  addi a5, a5, -1
38  addi a0, a5, 0
3C  jal ra, -0x38
40  addi s1, a0, 0
44  lw a5, -20(s0)
48  addi a5, a5, -2
4C  addi a0, a5, 0
50  jal ra, -0x4C
54  addi a5, a0, 0
58  add a5, s1, a5
5C  addi a0, a5, 0
60  lw ra, 28(sp)
64  lw s0, 24(sp)
68  lw s1, 20(sp)
6C  addi sp, sp, 32
70  jalr zero, 0(ra)
74  addi sp, sp, -16
78  sw ra, 12(sp)
7C  sw s0, 8(sp)
80  addi s0, sp, 16
84  addi a0, zero, 10
88  jal ra, -0x84
8C  jal zero, 0
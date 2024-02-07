# %%

# Parse dump file from Verilator
# The last 9 lines are output in the following format, so extract the values of registers x0 through x31

'''
x0 (zero):= 00000000, x1 ( ra ):= 00000010, x2 ( sp ):= 0000001e, x3 ( gp ):= 00000001, 
x4 ( tp ):= 00000002, x5 ( t0 ):= 00000002, x6 ( t1 ):= 0000001a, x7 ( t2 ):= 00000000, 
x8 ( s0 ):= 00000000, x9 ( s1 ):= 00000000, x10( a0 ):= 00000000, x11( a1 ):= 00000000, 
x12( a2 ):= 00000000, x13( a3 ):= 00000000, x14( a4 ):= 0000001a, x15( a5 ):= 00000000, 
x16( a6 ):= 00000000, x17( a7 ):= 0000005d, x18( s2 ):= 00000000, x19( s3 ):= 00000000, 
x20( s4 ):= 00000000, x21( s5 ):= 00000000, x22( s6 ):= 00000000, x23( s7 ):= 00000000, 
x24( s8 ):= 00000000, x25( s9 ):= 00000000, x26( s10):= 00000000, x27( s11):= 00000000, 
x28( t3 ):= 00000000, x29( t4 ):= 00000000, x30( t5 ):= 00001044, x31( t6 ):= 0000000b, 

'''

def parse_dump_verilator(dump_file) -> list:
    with open(dump_file, 'r') as f:
        lines = f.readlines()

    registers = []
    for line in lines[-9:-1]:
        for start_pos in [12, 34, 56, 78]:
            register = line[start_pos:start_pos+8]
            register = int(register, 16)
            registers.append(register)
    return registers

# %%

# Parse dump file from FPGA
# Each line is output in the following format, so extract the values of registers x0 through x31

'''
ret[ 0] = 0x00000000
ret[ 1] = 0x00000010
...
ret[34] = 0x00000000
ret[35] = 0x00000000
'''

def parse_dump_fpga(dump_file) -> list:
    with open(dump_file, 'r') as f:
        lines = f.readlines()

    registers = []
    for line in lines:
        register = line[12:20]
        register = int(register, 16)
        registers.append(register)
    return registers

# %%

# For each testcase, compare the values of registers from Verilator and FPGA

def compare_results(verilator_dump_path, fpga_dump_path, testcase) -> bool:
    verilator_dump = parse_dump_verilator(f'{verilator_dump_path}/{testcase}.hex.txt')
    fpga_dump = parse_dump_fpga(f'{fpga_dump_path}/{testcase}.ret')

    for i in range(32):
        if verilator_dump[i] != fpga_dump[i]:
            print(f'Error: {testcase} x{i} verilator={verilator_dump[i]}, fpga={fpga_dump[i]}')
            return False
    print(f'OK: {testcase}')
    return True

# %%

import os

verilator_dump_path = '../test/dump'
fpga_dump_path = '../../results_fpga'
testcases = [os.path.splitext(f)[0].split('.')[0] for f in os.listdir(verilator_dump_path) if f.endswith('.hex.txt')]
for testcase in testcases:
    compare_results(verilator_dump_path, fpga_dump_path, testcase)

# %%

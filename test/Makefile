VERILATOR = verilator
VERILATOR_FLAGS = --cc --exe --trace --trace-params --trace-structs --trace-underscore
SRCS := ../src/instructions.svh ../src/alu.sv ../src/regfile.sv ../src/csr.sv ../src/pc.sv ../src/ram.sv ../src/decode.sv ../src/core.sv
TEST_SRC := test_core.cpp
TOP_MODULE := riscoffee_core
TEST_DIR = .
OBJ_DIR = obj_dir
EXE_FILE = $(OBJ_DIR)/V$(TOP_MODULE)

# デフォルトターゲット
all: Vcore run

# Vcoreターゲット
Vcore: $(EXE_FILE)

$(EXE_FILE): $(SRCS) $(TEST_SRC)
	$(VERILATOR) $(VERILATOR_FLAGS) $(SRCS) -exe $(TEST_SRC) --top-module $(TOP_MODULE)
	make -C $(OBJ_DIR) -f V$(TOP_MODULE).mk

# runターゲット
run: $(EXE_FILE)
	./$(EXE_FILE)

# cleanターゲット
clean:
	rm -rf $(OBJ_DIR) simx.vcd

.PHONY: all Vcore run clean

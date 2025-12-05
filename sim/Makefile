#######################################################################################
# Parameters
#######################################################################################

# Directories
COMP_DIR = ../components
SEQ_DIR  = ../sequences
TEST_DIR = ../tests
RTL_DIR  = ../rtl

# Test settings
TEST_NAME = bmu_regression_test
VERBOSITY = UVM_MEDIUM

# RTL Design files
RTL_DESIGN_FILES = \
	$(RTL_DIR)/rtl_def.sv \
	$(RTL_DIR)/rtl_defines.sv \
	$(RTL_DIR)/rtl_lib.sv \
	$(RTL_DIR)/rtl_pdef.sv \
	$(RTL_DIR)/Bit_Manipulation_Unit.sv

# Interface, package, and testbench files
INTERFACE_FILE = $(COMP_DIR)/bmu_interface.sv
PACKAGE_FILE   = $(COMP_DIR)/bmu_pkg.sv
TB_FILE        = $(COMP_DIR)/bmu_tb.sv

# Complete file list
ALL_FILES = $(RTL_DESIGN_FILES) $(INTERFACE_FILE) $(PACKAGE_FILE) $(TB_FILE)

# Include directories
INCDIR = +incdir+$(COMP_DIR)+$(SEQ_DIR)+$(TEST_DIR)+$(RTL_DIR)

# Xrun flags
XRUN_FLAGS = -uvm -sv -access +rwc -coverage all -covwork coverage_db
COV_FLAGS  = -coverage all -covwork coverage_db

#######################################################################################
# Targets
#######################################################################################

# Default target: clean and run simulation
all: clean run_sim

# Run full simulation
run_sim:
	@echo "Running UVM BMU Simulation with test: $(TEST_NAME)"
	xrun $(XRUN_FLAGS) $(INCDIR) $(ALL_FILES) +UVM_TESTNAME=$(TEST_NAME) +UVM_VERBOSITY=$(VERBOSITY)

# Run test using testbench's run_test() method
test:
	xrun $(XRUN_FLAGS) $(INCDIR) $(ALL_FILES) +UVM_VERBOSITY=$(VERBOSITY)

# Generate coverage report
cov_report:
	@echo "Generating Coverage Report..."
	imc -exec -noconsole -batch -init coverage_report.tcl

# Open Verisium interactive GUI for debugging
wave:
	xrun $(XRUN_FLAGS) $(INCDIR) $(ALL_FILES) +UVM_TESTNAME=$(TEST_NAME) -debug_opt verisium_interactive

# Open IMC coverage analyzer GUI
imc:
	@echo "Opening IMC Coverage Analyzer..."
	imc -load coverage_db/scope/test/ -gui

# Compile only (without simulation)
compile:
	@echo "Compiling UVM BMU Environment..."
	xrun $(XRUN_FLAGS) $(INCDIR) -compile $(ALL_FILES)

# Check compilation / elaboration only
check:
	@echo "Checking compilation..."
	xrun $(XRUN_FLAGS) $(INCDIR) -elaborate $(ALL_FILES)

# Open SimVision GUI
simvision:
	@echo "Running with GUI..."
	xrun $(XRUN_FLAGS) $(INCDIR) -gui $(ALL_FILES) +UVM_TESTNAME=$(TEST_NAME) +UVM_VERBOSITY=$(VERBOSITY)

# Clean generated files and logs
clean:
	@echo "Cleaning generated files..."
	rm -rf xrun.* waves.shm xcelium.d .simvision INCA_libs \
		*.log *.history *.fsdb *.key verisium_debug_logs \
		.coverage_db cov_work verisium_debug_logs_backup \
		.reset_sync_save .reinvoke.sim ida.db .probeFlags.flg

.PHONY: all run_sim test cov_report wave imc compile check simvision clean

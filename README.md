# BMU Verification Environment



**A UVM-based verification environment for the RISC-V Bit Manipulation Unit (BMU)**

</div>

---


## Overview

The **Bit Manipulation Unit (BMU)** is a synthesizable RTL block that implements bit manipulation functionality compliant with the **RISC-V BitManip extension**.  

This verification environment provides **comprehensive UVM-based testing** for all supported instructions and ensures robust functionality across various operational scenarios.

---




## BMU Architecture



| Port Name       | Direction | Width   | Description |
|-----------------|-----------|--------|-------------|
| `clk`           | Input     | 1 bit  | System clock |
| `rst_l`         | Input     | 1 bit  | Active-low synchronous reset |
| `scan_mode`     | Input     | 1 bit  | Scan test mode |
| `valid_in`      | Input     | 1 bit  | Instruction valid flag |
| `ap`            | Input     | Struct | Decoded instruction control signals |
| `csr_ren_in`    | Input     | 1 bit  | CSR read-enable |
| `csr_rddata_in` | Input     | 32 bit | CSR read data |
| `a_in`, `b_in`  | Input     | 32 bit | Operand A and B |
| `result_ff`     | Output    | 32 bit | Final result |
| `error`         | Output    | 1 bit  | Error flag |

### Functional Submodules

- ** Arithmetic Unit**: ADD, SUB, SHxADD
- ** Shift Logic**: SLL, SRL, SRA, ROL, ROR
- ** Count Logic**: CLZ, CTZ, CPOP
- ** Extension Logic**: SEXT.B, SEXT.H
- ** Compare Logic**: MIN, MAX
- ** Pack Logic**: PACK, PACKU, PACKH
- ** Bit Logic**: BSET, BCLR, BINV, BEXT

---

##  Verification Environment

###  Components

- ** Environment**: UVM top-level
- ** Agent**: Modular driver + monitor
- ** Driver**: Stimulus execution
- ** Monitor**: Signal monitoring
- ** Scoreboard**: Result checking
- ** Sequences**: Directed & random tests
- ** Tests**: Instruction + error + regression tests



##  Directory Structure

```text
BMU-Verification/
├── README.md
├── Makefile
├── .gitignore
├── components/
│   ├── bmu_interface.sv
│   ├── bmu_pkg.sv
│   ├── bmu_tb.sv
│   └── env/ (driver, monitor, agent, scoreboard)
├── dut_rm/ (reference model)
├── rtl/ (BMU RTL files)
├── sequences/ (UVM sequences)
└── tests/ (UVM test cases)

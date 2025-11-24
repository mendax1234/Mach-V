# Verification & Simulation

This section outlines the verification strategy for the Hydra-V processor, including unit testing and full system simulation.

## Simulation Directory Structure

The `sim/` directory contains all testbench and verification artifacts:

* **`sim/tb/`**: Verilog testbenches for individual modules (ALU, RegFile) and the top-level core.
* **`sim/hex/`**: Pre-compiled hexadecimal files (machine code) loaded into instruction memory for simulation.

## Prerequisites

Ensure you have the following tools installed:

1. **Xilinx Vivado** (for Behavioral Simulation)
2. **Verilator** (Optional, for faster C++ based simulation)
3. **GTKWave** (for viewing waveform dumps outside Vivado)

## Running Simulations

### Unit Level Testing

Unit tests verify specific components before integration.

```bash
# Example: Running the ALU testbench
cd sim/tb
xvlog alu.v alu_tb.v
xelab -debug typical alu_tb -s alu_sim
xsim alu_sim -R
```

### Top Level System Test

To verify the full processor pipeline:

1. Load a program hex file into `sim/hex/main.hex`.
2. Run the top-level testbench `tb_core.v`.
3. Observe the `d_mem` and register file changes.

!!! tip "Debugging with Waveforms" If the processor stalls, check the stall_signal and flush lines in the Waveform viewer. A permanent high signal usually indicates a lockup in the Hazard Unit.

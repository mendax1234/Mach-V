# Mach-V

**Mac-V** is an open-source RISC-V processor implementation targeting the Digilent **Nexys 4** FPGA. The project aims to evolve from a standard 5-stage pipeline into a Superscalar, Out-of-Order (OoO), and Multi-core architecture.

Current status: **RV32IM Pipelined Core running CoreMark.**

## Roadmap

The project follows a staged evolution towards high-performance parallel processing:

- [x] **Phase 1: Baseline Core**
  - 5-Stage Classical Pipeline (F, D, E, M, W)
  - Full Hazard Handling & Forwarding
  - RV32IM ISA Support
  - Verified with **CoreMark** Benchmark
- [x] **Phase 2: Pipeline & Latency Optimization**
  - Move Branch Logic to Memory (M) Stage to reach 100MHz or above.
  - Optimize Multiply/Divide logic to minimize stall cycles. (Use fast multiplier and non-restoring division)
  - Improve the Hazard Unit to prevent extra stalls.
  - Implement the Clock Wizard for customized timing.
- [ ] **Phase 3: Advanced Architecture**
  - Dynamic Branch Prediction (BHT/BTB)
  - Superscalar Execution (Dual-issue)
  - Out-of-Order Execution (The broadcasting diagram on Lec 06)
- [ ] **Phase 4: Multicore and Multithread System**
  - Simultaneous Multithreading (SMT)
  - Multi-Core Implementation

## Project Structure

This repository is organized to separate the core RTL from board-specific implementations and software.

```text
Mach-V/
├── rtl/              # Core CPU Logic (Platform Agnostic)
│   ├── core/         # Pipeline stages, ALU, Hazards
│   └── peripherals/  # UART, SPI, Timers
├── fpga/             # FPGA Implementation
│   └── nexys4/       # Constraints and Top-Level Wrappers for Nexys 4
├── sw/               # CoreMark, OLED Demo, Benchmarks
└── sim/              # Testbenches and memory initialization files
```

## Quick Start

### Prerequisites

- **Hardware:** Digilent Nexys 4 / Nexys 4 DDR (Artix-7 FPGA)
- **Software:** Xilinx Vivado 2025.2
- **Toolchain:** RISC-V GNU Toolchain (`riscv32-unknown-elf-gcc`)

### Building Software

To compile the CoreMark benchmark and generate memory initialization files:

```bash
cd sw/apps/coremark
make
# Output: data.hex & code.hex 
# (Change name to DMEM.mem and IROM.mem, then load into Vivado Block RAM)
```

### FPGA Deployment

1. Open Vivado and create a new project.
2. Add all files from `rtl/` and `fpga/nexys4/wrapper/`.
3. Add constraints from `fpga/nexys4/constraints/`.
4. Add the generated `.mem` file as sources for Block RAM initialization.
5. Generate Bitstream and Program Device.

## Performance

- **Frequency:** *100MHz*
- **CoreMark Score:**
  - **Coremarks:** *153*
  - **Coremarks/MHz:** *1.53*

## License

[MIT License](LICENSE)

# Mach-V

**Mach-V** is an open-source RISC-V processor implementation targeting the Digilent **Nexys 4 DDR** FPGA. The project aims to evolve from a standard 5-stage pipeline into a Superscalar, Out-of-Order (OoO), and Multi-core architecture.

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
  - Out-of-Order Execution (The broadcasting diagram on CG3207 Lec 06)
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
│   └── nexys4-ddr/       # Constraints and Top-Level Wrappers for Nexys 4 DDR
├── sw/               # CoreMark, OLED Demo, Benchmarks
└── sim/              # Testbenches and memory initialization files
```

## Quick Start

The guide can be found in the [Mach-V Document](https://mendax1234.github.io/Mach-V/sw/).

## License

[MIT License](LICENSE)

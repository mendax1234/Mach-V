# Mach-V

**Mach-V** is an open-source RISC-V processor implementation targeting the Digilent **Nexys 4 DDR** FPGA. The project aims to evolve from a standard 5-stage pipeline into a Superscalar and high-performance architecture.

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
- [x] **Phase 3: Advanced Architecture**
  - 1-bit Dynamic Branch Prediction (BHT/BTB)
  - Superscalar Execution (Dual-issue)
- [ ] **Phase 4: High Performance**
  - RTL Transformations: time interleaving for multithreading and repipelining for frequency boost.
  - High performance branch predictors.
  - Simplify the Dual-Issue unit to increase the ILP.

## Project Structure

This repository is organized to separate the core RTL from board-specific implementations and software.

```text
Mach-V/
├── rtl/              # Core CPU Logic (Platform Agnostic)
│   ├── core/         # Pipeline stages, ALU, Hazards
│   └── peripherals/  # UART, SPI, Timers
├── sw/               # CoreMark, OLED Demo, Benchmarks
└── sim/              # Testbenches and memory initialization files
```

## Quick Start

The guide can be found in the [Mach-V Document](https://mendax1234.github.io/Mach-V/sw/).

## License

[MIT License](LICENSE)

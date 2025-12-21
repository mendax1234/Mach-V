# Changelog

## Mach-V Processor

### 2.0 <small> Dec 20, 2025 </small> { id="2.0" }

**Focus:** Timing optimization and hardware acceleration.

- **Enhanced Clock Frequency:** Integrated Clock Wizard to boost operating frequency to **115 MHz** (from 100 MHz baseline).
- **Critical Path Optimization:** Relocated PC logic from the Execute (EXE) stage to the Memory (MEM) stage to relax timing constraints.
- **Hardware-Accelerated Arithmetic:** Replaced native multiplier/divider designs with optimized AMD/Xilinx IP cores for high-performance integer arithmetic.

### 1.0 <small> Nov 15, 2025 </small> { id="1.0" }

**Focus:** Baseline implementation featuring a classic RISC-V scalar architecture.

- **Classic 5-Stage Pipeline:** Implemented standard Fetch, Decode, Execute, Memory, and Writeback stages.
- **Comprehensive Hazard Management:** Added dedicated hardware for data forwarding and hazard detection to resolve data/control hazards.
- **Scalar In-Order Execution:** Established single-issue sequential execution ensuring deterministic behavior and architectural simplicity.

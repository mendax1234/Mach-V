# Changelog

## Mach-V Processor

### 1.2 <small> Feb 21, 2026 </small> { id="1.2" }

**Focus:** 1-bit Branch Predictor and Block RAM optimization.

- **1-bit Branch Predictor:** Implemented a simple 1-bit branch predictor to improve control flow efficiency by predicting the outcome of branch instructions, resulting in a 15% improvement in Coremark scores.
- **Block RAM Optimization:** Utilized Block RAM for both IROM and DMEM, reducing the area of the design by 50% compared to the previous version.

### 1.1 <small> Dec 20, 2025 </small> { id="1.1" }

**Focus:** Timing optimization and hardware acceleration.

- **Enhanced Clock Frequency:** Integrated Clock Wizard to boost operating frequency to **115 MHz** (from 100 MHz baseline).
- **Critical Path Optimization:** Relocated PC logic from the Execute (EXE) stage to the Memory (MEM) stage to relax timing constraints.
- **Hardware-Accelerated Arithmetic:** Replaced native multiplier/divider designs with optimized AMD/Xilinx IP cores for high-performance integer arithmetic.

### 1.0 <small> Nov 15, 2025 </small> { id="1.0" }

**Focus:** Baseline implementation featuring a classic RISC-V scalar architecture.

- **Classic 5-Stage Pipeline:** Implemented standard Fetch, Decode, Execute, Memory, and Writeback stages.
- **Comprehensive Hazard Management:** Added dedicated hardware for data forwarding and hazard detection to resolve data/control hazards.
- **Scalar In-Order Execution:** Established single-issue sequential execution ensuring deterministic behavior and architectural simplicity.

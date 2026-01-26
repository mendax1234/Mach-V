# Memory Subsystem

## System Memory Map

Followed by the convention set in [NUS CG3207](https://nus-cg3207.github.io/labs/rv_resources/rv_memmap/), the Mach-V processor uses a memory-mapped I/O architecture. The address space is divided into Instruction Memory, Data Memory, and Peripheral (MMIO) regions.

!!! info "Configuration Source"
    The memory capacities defined below are determined by parameters in `Wrapper.v`. For example,
    ```verilog
    localparam IROM_DEPTH_BITS = 15;     // for 2^15 words = 32KB
    localparam DMEM_DEPTH_BITS = 14;     // for 2^14 words = 16KB
    localparam MMIO_DEPTH_BITS = 8;      // for 2^8 words = 1KB
    ```

    If you modify these parameters in `Wrapper.v`, you must update your linker script and stack initialization accordingly.
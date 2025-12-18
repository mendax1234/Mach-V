---
icon: material/speedometer
---

# CoreMark Benchmark

The [CoreMark](https://www.eembc.org/coremark/) benchmark is used to evaluate the performance of the Mach-V processor. It measures the CPU's ability to handle list processing, matrix manipulation, and state machine execution.

## Source Code Organization

The CoreMark source code and build scripts are located in the `sw/coremark/` directory.

## Porting Implementation

The CoreMark port for Mach-V is based on the barebones implementation. To adapt it for the Mach-V memory map, modifications are required in `sw/coremark/barebones/core_portme.c` and `sw/coremark/barebones/ee_printf.c`.

### System Timer

CoreMark requires a method to measure time to calculate the performance score. In `core_portme.c`, the `barebones_clock()` function is modified to read the Mach-V `CYCLECOUNT` system counter.

**Modification:** Update `hardwareCounterAddr` to point to the Mach-V [system counter](./index.md/#system-counters) address (`0xFFFF00A0`).

```c
CORETIMETYPE barebones_clock() {
    // Pointer to the Mach-V System Counter (CYCLECOUNT)
    volatile unsigned int* hardwareCounterAddr = (unsigned int*)0xffff00a0;
    
    unsigned int hardwareCounter;

    // Read hardwareCounter (Execution Cycle)
    hardwareCounter = *hardwareCounterAddr;
    
    return (CORETIMETYPE)hardwareCounter;
}
```

### UART Output

To output the benchmark results to the console, the UART transmission function must be mapped to the correct MMIO addresses.

**Modification:** In `ee_printf.c`, update the pointers in `uart_send_char()` to match the Mach-V UART peripheral addresses. The relevant addresses are introduced in [System Memory Map](./index.md/#communication-uart).

```c
void uart_send_char(char c) {
    volatile unsigned int *UART_TX_READY_ADDR = (unsigned int*)0xFFFF0008;
    volatile unsigned char *UART_TX_ADDR = (unsigned char*)0xFFFF000C;

    // Wait until UART is ready (LSB == 1 indicates ready)
    while ((*UART_TX_READY_ADDR & 0x1) == 0);

    // Write character to the transmission buffer
    *UART_TX_ADDR = c;

    // Optional: Wait for transmission completion
    while ((*UART_TX_READY_ADDR & 0x1) == 0);
}
```

## Build Configuration

### Setting Clock Frequency

To ensure the CoreMark score (Iterations/Sec) is calculated correctly, the build script must know the target processor frequency.

Modify the `Makefile` under `sw/coremark` to set the `CLOCKS_PER_SEC` flag. This value must match the frequency of the Mach-V processor. For example, for a design running at 50 MHz:

```makefile
CLOCKS_PER_SEC = 50000000
```

!!! warning
    If `CLOCKS_PER_SEC` does not match the actual hardware clock frequency, the reported CoreMark/MHz score will be mathematically incorrect.

!!! success "Ready to Run"
    With the porting layer configured and the frequency set, the CoreMark benchmark is ready to run on Mach-V!

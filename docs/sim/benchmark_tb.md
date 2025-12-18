---
icon: material/speedometer
---

# Benchmark Testbench

This testbench is designed for non-interactive applications, such as the [CoreMark](../sw/benchmark.md#coremark-benchmark) benchmark. Its primary goal is to run the processor at full speed and capture the output without requiring manual user input.

## Key features

### Zero-Stall UART Configuration

Since the benchmark relies on printf for reporting results but has no human operator, the UART input is disabled, and the output is forced to be "always ready."

* **RX (Input)**: `UART_RX_valid` is tied to `0`, ensuring the CPU never receives spurious input.
* **TX (Output)**: `UART_TX_ready` is hardcoded to `1`, preventing the CPU from stalling while waiting for the terminal to accept a character.

### Output Monitoring

Instead of opening a graphical terminal, the testbench monitors the `UART_TX` line directly. Whenever the CPU asserts `UART_TX_valid`, the testbench grabs the character and prints it to the Vivado Tcl console using `$display`.

```verilog
always @(posedge CLK) begin
    if (UART_TX_valid) begin
        // Prints the ASCII character sent by the CPU
        $display("UART_TX: %h", UART_TX); 
    end
end
```

### Simulation Timeout

To prevent the simulation from running indefinitely (in case of software crashes or infinite loops), a hard limit is set. The simulation automatically stops after 50ms (5,000,000,000 ns), which is sufficient for one iteration of the benchmark.

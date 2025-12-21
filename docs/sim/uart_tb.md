# UART Application Testbench

This testbench verifies the interactive capabilities of the processor, specifically focusing on the [UART Calculator](../sw/uart_calculator.md) application. Unlike the [benchmark simulation](./benchmark_tb.md), this testbench actively injects data and adheres to a strict handshaking protocol.

## The `send_uart` Task

The core of this verification is the `send_uart` task, which automates the entry of complex commands. It constructs a 9-byte packet consisting of:

1. **Command Byte**: The ASCII character for the operation. (e.g., `d` for division. For the full list of commands, refer to the [UART Calculator documentation](../sw/uart_calculator.md#command-reference).)
2. **Operand 1 (4 bytes)**: The first 32-bit number.
3. **Operand 2 (4 bytes)**: The second 32-bit number.

### Handshaking Protocol

The task simulates a real UART controller by waiting for the CPU to acknowledge receipt of each byte before sending the next.

```verilog
// Wait until CPU acknowledges (reads from UART_RX)
wait (UART_RX_ack == 1); 
UART_RX_valid = 0;
// Wait until CPU clears ack before sending next byte
wait (UART_RX_ack == 0);
```

## Test Coverage

You are encouraged to extend tb_uart.v with additional test cases to verify specific scenarios. When adding new tests, please refer to the [UART Calculator Command Reference](../sw/uart_calculator.md#command-reference) to ensure the correct the command code is used.

---
icon: material/calculator
---

# UART Calculator

This is a simple calculator program that is used to test the basic functionality of the Hydra-V processor. It contains all the basic instructiosn from RISC-V I and M extensions, and performs arithmetic operations based on user input via UART.

## Source Code Organization

The source code for the UART Calculator is located in the `sw/uart_calculator/` directory. The main source file is `uart_calculator.c`, which contains the implementation of the calculator logic and UART communication.

## Porting Implementation

### UART Output

As the calculator uses UART to communicate with the Hydra-V processor, if the MMIO addresses are changed, the code in `uart_calculator.c` must be updated accordingly. The MMIO definitions are located at the top of the `uart_calculator.c` file,

```c
#define MMIO_BASE 0xFFFF0000
#define UART_RX_VALID_OFF 0x00
#define UART_RX_DATA_OFF 0x04
#define UART_TX_READY_OFF 0x08
#define UART_TX_DATA_OFF 0x0C
#define SEVENSEG_OFF 0x80
```

!!! info
    If you are using different MMIO addresses for UART or other peripherals, make sure to update these definitions accordingly.

### DMEM Initialization

The application pre-loads data into Data Memory (DMEM) to test Load/Store instructions. This is handled via initialized global arrays in C, which the linker places in the `.data` section.

```c
// Pre-loaded test patterns for Load operations
uint32_t test_data[4] = {
    0x12345678,
    0x9ABCDEF0,
    0xAABBCCDD,
    0xEEFF0011};
```

## Build Configuration

There is nothing much to customize or change in the `Makefile`, `ld.script` and `crt.s` files for this application. This is also why this application can be regarded as a template for other new applications.

## Application Usage

The calculator operates using a strictly defined 9-byte communication protocol over UART.

### Communication Protocol

For every operation, the user must send exactly **9 bytes** to the processor:

1. **Command 1(1 Byte)**: An ASCII character selecting the operation (see table below).
2. **Operand 1(4 Bytes)**: The first 32-bit argument, sent Big-Endian (MSB first).
3. **Operand 2(4 Bytes)**: The second 32-bit argument, sent Big-Endian (MSB first).

**Output**: The result of the operation is written to the **7-segment Display** MMIO address.

### Command Reference

| Category           | Command | ASCII | Operation          | Description                                                                 |
|--------------------|---------|-------|--------------------|-----------------------------------------------------------------------------|
| **Arithmetic**     | ADD     | a     | op1 + op2          | 32-bit Addition                                                             |
|                    | SUB     | s     | op1 - op2          | 32-bit Subtraction                                                          |
| **Logical**        | AND     | c     | op1 & op2          | Bitwise AND                                                                 |
|                    | OR      | o     | op1 \| op2         | Bitwise OR                                                                  |
|                    | XOR     | x     | op1 ^ op2          | Bitwise XOR                                                                 |
| **Shift**          | SLL     | L     | op1 << op2         | Shift Left Logical                                                          |
|                    | SRL     | R     | op1 >> op2         | Shift Right Logical                                                         |
|                    | SRA     | A     | op1 >> op2         | Shift Right Arithmetic (sign-extended)                                      |
| **Comparison**     | SLT     | l     | op1 < op2          | Set if Less Than (Signed)                                                    |
|                    | SLTU    | u     | op1 < op2          | Set if Less Than (Unsigned)                                                  |
| **Multiply / Div** | MUL     | m     | op1 * op2          | Low 32 bits of product                                                       |
|                    | MULH    | H     | op1 * op2          | High 32 bits (Signed)                                                        |
|                    | MULHU   | h     | op1 * op2          | High 32 bits (Unsigned)                                                      |
|                    | DIV     | d     | op1 / op2          | Signed Division                                                              |
|                    | DIVU    | D     | op1 / op2          | Unsigned Division                                                            |
|                    | REM     | r     | op1 % op2          | Signed Remainder                                                             |
|                    | REMU    | M     | op1 % op2          | Unsigned Remainder                                                           |
| **Memory Access**  | LOAD    | 1..4  | Mem[op1]           | Reads from `test_data`. 1=LB, 2=LBU, 3=LH, 4=LHU                             |
|                    | STORE   | 5..6  | Mem[op1] = op2     | Writes to `scratch_mem`. 5=SB, 6=SH                                         |

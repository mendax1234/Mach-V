# Software Development Guide

This guide explains how to write, compile, and deploy software for the Hydra-V processor.

## Software Directory Structure

The `sw/` directory is organized by application:

* **`sw/coremark/`**: The industry-standard CoreMark benchmark ported for this architecture.
* **`sw/oled-demo/`**: Drivers and demo code for the OLED display on the Nexys 4.

## Memory Map

The processor uses a flat 32-bit address space.

| Address Range | Size | Device | Description |
| :--- | :--- | :--- | :--- |
| `0x0000_0000` | 64 KB | **Instruction Memory** | Read-Only program storage (BRAM). |
| `0x0010_0000` | 64 KB | **Data Memory** | Read/Write RAM for stack and variables. |
| `0x8000_0000` | 4 B | **GPIO_LEDS** | Write logic `1` to turn on board LEDs. |
| `0x8000_0004` | 4 B | **UART_TX** | Write a character (byte) to send via Serial. |

## Toolchain Setup

You need the RISC-V GNU Toolchain to compile C code into machine code.

1. **Install Toolchain:**

    ```bash
    sudo apt-get install gcc-riscv64-unknown-elf
    ```

2. **Compilation Steps:**
    We treat the processor as "Bare Metal" (no Operating System).

    ```bash
    # 1. Compile C to Object
    riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -c main.c -o main.o

    # 2. Link (using custom linker script)
    riscv64-unknown-elf-ld -T linker.ld main.o -o main.elf

    # 3. Generate Hex File (for Verilog $readmemh)
    riscv64-unknown-elf-objcopy -O verilog main.elf main.hex
    ```

## Example: OLED Demo

To run the OLED demo located in `sw/oled-demo/barebones`:

1. Navigate to the folder.
2. Run `make hex`.
3. Copy the generated `.hex` file to `sim/hex/` for simulation or `fpga/` for synthesis.

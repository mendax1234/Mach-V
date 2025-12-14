# Software Development Guide

This guide explains how to write, compile, and run different software on the Hydra-V processor.

## Software Directory Structure

The `sw/` directory is organized by application. For example:

* `sw/coremark/` contais the CoreMark benchmark source code and build scripts.

## System Memory Map

Followed by the convention set in [NUS CG3207](https://nus-cg3207.github.io/labs/rv_resources/rv_memmap/), the Hydra-V processor uses a memory-mapped I/O architecture. The address space is divided into Instruction Memory, Data Memory, and Peripheral (MMIO) regions.

!!! info "Configuration Source"
    The memory capacities defined below are determined by parameters in `Wrapper.v`. For example,
    ```verilog
    localparam IROM_DEPTH_BITS = 15;     // for 2^15 words = 32KB
    localparam DMEM_DEPTH_BITS = 14;     // for 2^14 words = 16KB
    localparam MMIO_DEPTH_BITS = 8;      // for 2^8 words = 1KB
    ```

    If you modify these parameters in `Wrapper.v`, you must update your linker script and stack initialization accordingly.

### Main Memory

| Address Range              | Name                        | Permissions        | Description |
|---------------------------|-----------------------------|--------------------|-------------|
| `0x00400000 – 0x00407FFF` | IROM (Instruction Memory)   | RO (Read-Only)     | Capacity: 8,192 words (32 KB). Based on `IROM_DEPTH_BITS = 15`. |
| `0x10010000 – 0x10013FFF` | DMEM (Data Memory)          | RW (Read-Write)    | Capacity: 4,096 words (16 KB). Used for storing constants and variables. Based on `DMEM_DEPTH_BITS = 14`. |

!!! warning "Addressing Constraints"
    Accesses must be aligned to 4-byte boundaries.

### Memory-Mapped Peripherals (MMIO)

All peripherals are mapped to the upper memory range starting at `0xFFFFxxxx`.

#### Communication (UART)

| Address      | Register Name | Perms | Description                                                                                                                  |
| ------------ | ------------- | ----- | ---------------------------------------------------------------------------------------------------------------------------- |
| `0xFFFF0000` | UART_RX_VALID | RO    | Receive Status. Data is valid to read from `UART_RX` only when the LSB (Least Significant Bit) of this register is set to 1. |
| `0xFFFF0004` | UART_RX       | RO    | Receive Data. Reads input from the keyboard. Only the LSByte (lowest 8 bits) contains valid data.                            |
| `0xFFFF0008` | UART_TX_READY | RO    | Transmit Status. Data is safe to write to `UART_TX` only when the LSB of this register is set to 1.                          |
| `0xFFFF000C` | UART_TX       | WO    | Transmit Data. Sends output to the display/console. Only the LSByte is writeable.                                            |

#### On-Board I/O (GPIO)

| Address      | Register Name | Perms | Description |
|-------------|---------------|-------|-------------|
| `0xFFFF0060` | LED | WO | LED control register |
| `0xFFFF0064` | DIP | RO | DIP switch input register |
| `0xFFFF0068` | PB | RO | Push button input register |
| `0xFFFF0080` | SEVENSEG | WO | 7-segment display output register |

!!! note "Register Details"
    `LED -- 0xFFFF0060 (WO)`

    :   The lower **8 bits** are user-writeable. The upper bits are hardwired as follows:

        - **[7:0]** user writeable,
        - **[8]** divided clock,
        - **[15:9]** program counter `[8:2]`.

    `DIP -- 0xFFFF0064 (RO)`

    :   Reads the state of the **16 on-board switches**, covering switch range **SW15–SW0**.

    `PB -- 0xFFFF0068 (RO)`

    :   Only the lowest **3 bits** are valid.

        - **[2]** BTNR (Right),
        - **[1]** BTNC (Center),
        - **[0]** BTNL (Left).

        The remaining buttons are hardwired: **BTND** resets the system, while **BTNU** pauses execution.

    `SEVENSEG -- 0xFFFF0080 (WO)`

    :   Writes an **8-digit hexadecimal number** to the 7-segment display.

#### Sensor & Display Modules

| Address      | Register Name | Perms | Description                                                               |
| ------------ | ------------- | ----- | ------------------------------------------------------------------------- |
| `0xFFFF0020` | OLED_COL      | WO    | Sets the OLED pixel column index (0 – 95).                                |
| `0xFFFF0024` | OLED_ROW      | WO    | Sets the OLED pixel row index (0 – 63).                                   |
| `0xFFFF0028` | OLED_DATA     | WO    | Writes data to the pixel. Format depends on `OLED_CTRL`.                  |
| `0xFFFF002C` | OLED_CTRL     | WO    | Controls OLED data format and operation modes.                            |
| `0xFFFF0040` | ACCEL_DATA    | RO    | Reads accelerometer data (refer to peripherals documentation for format). |
| `0xFFFF0044` | ACCEL_DREADY  | RO    | Data Ready. LSB is set when a new reading is available.                   |

#### System Counters

| Address      | Register Name | Perms | Description                                                    |
| ------------ | ------------- | ----- | -------------------------------------------------------------- |
| `0xFFFF00A0` | CYCLECOUNT    | RO    | Returns the number of clock cycles elapsed since system reset. |

## Toolchain Setup

I used the RISC-V GNU Toolchain to compile C code into machine code (hex files) and then load them into the Hydra-V processor's IROM (`AA_IROM.mem`) and DMEM (`AA_DMEM.mem`).

### Install Toolchain

The toolchain that I used is pre-built and can be found on [GitHub](https://github.com/stnolting/riscv-gcc-prebuilt). I chose the `rv32i-131023` version. The installation guide is also available on the [repository](https://github.com/stnolting/riscv-gcc-prebuilt?tab=readme-ov-file#installation).

### Build Configuration

To compile C code into hex files for IROM and DMEM, I used three files: `Makefile`, `ld.script` and `crt.s`. For every C program that is newly written, these three files need to be added and modified accordingly.

#### `Makefile`

`Makefile` defines the rules for the `make` command to work. Make sure the `GCC_DIR` is correct and feel free to change the `CFLAGS` as you wish (like changing the Optimization flag from `-O2` to `-O3` etc).

!!! info
    You can get a template from any one of the application, but I recommend the [`sw/calculator/Makefile`](https://github.com/mendax1234/Hydra-V/blob/main/sw/calculator/Makefile).

#### `ld.script`

`ld.script` first specifies the size left for IROM and DMEM. In the Hydra-V processor,

* `ROM` stands for IROM, its `ORIGIN` is `0x00400000`, its `LENGTH` depends on the size of the `code.hex` generated.
* `RAM` stands for DMEM, its `ORIGIN` is `0x10010000`, its `LENGTH` depends on the size of the `data.hex` generated.

Secondly, it specifies which section in the compiled program goes to which memory region. This determines which part of the program is stored in IROM and which part is stored in DMEM. For example,

* the `.rodata` and `.data` sections are dumped into DMEM
* the `.text` section is dumped into IROM.

#### `crt.s`

The `crt.s` file is the entry point of the software. It sets up the execution environment before handing control to the C `main()` function.

For each new application, the `li sp, <address>` instruction needs to be modified to set the stack pointer (`sp`) to the top of DMEM. The stack grows downwards from high memory to low memory. Thus you should set the stack pointer to the very end of your available DMEM.

$$
\text{Initial SP} = \text{DMEM_BASE} + \text{DMEM_SIZE}
$$

For example, if your DMEM size is 7KB (the `sw/coremark` example), and the Hydra-V processor's DMEM base address is `0x10010000`, then the initial stack pointer should be set to:

```riscv
li sp, 0x10011C00  # 0x10010000 + 7 * 1024
```

!!! success
    Now you are ready to write, compile, and run your software on the Hydra-V processor! Feel free to move on to explore the existing software applications in the `sw/` directory.

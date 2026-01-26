# Software Development Guide

This guide explains how to write, compile, and run different software on the Mach-V processor.

## Software Directory Structure

The `sw/` directory is organized by application. For example:

* `sw/coremark/` contains the CoreMark benchmark source code and build scripts.

## Toolchain Setup

I used the RISC-V GNU Toolchain to compile C code into machine code (hex files) and then load them into the Mach-V processor's IROM (`AA_IROM.mem`) and DMEM (`AA_DMEM.mem`).

### Install Toolchain

The toolchain that I used is pre-built and can be found on [GitHub](https://github.com/stnolting/riscv-gcc-prebuilt). I chose the `rv32i-131023` version. The installation guide is also available on the [repository](https://github.com/stnolting/riscv-gcc-prebuilt?tab=readme-ov-file#installation).

### Build Configuration

To compile C code into hex files for IROM and DMEM, I used three files: `Makefile`, `ld.script` and `crt.s`. For every C program that is newly written, these three files need to be added and modified accordingly.

---

#### `Makefile`

`Makefile` defines the rules for the `make` command to work. Make sure the `GCC_DIR` is correct and feel free to change the `CFLAGS` as you wish (like changing the Optimization flag from `-O2` to `-O3` etc).

!!! info
    You can get a template from any one of the application, but I recommend the [`sw/calculator/Makefile`](https://github.com/mendax1234/Mach-V/blob/main/sw/calculator/Makefile).

---

#### `ld.script`

`ld.script` first specifies the size left for IROM and DMEM. In the Mach-V processor,

* `ROM` stands for IROM, its `ORIGIN` is `0x00400000`, its `LENGTH` depends on the size of the `code.hex` generated.
* `RAM` stands for DMEM, its `ORIGIN` is `0x10010000`, its `LENGTH` depends on the size of the `data.hex` generated.

Secondly, it specifies which section in the compiled program goes to which memory region. This determines which part of the program is stored in IROM and which part is stored in DMEM. For example,

* the `.rodata` and `.data` sections are dumped into DMEM
* the `.text` section is dumped into IROM.

---

#### `crt.s`

The `crt.s` file is the entry point of the software. It sets up the execution environment before handing control to the C `main()` function.

For each new application, the `li sp, <address>` instruction needs to be modified to set the stack pointer (`sp`) to the top of DMEM. The stack grows downwards from high memory to low memory. Thus you should set the stack pointer to the very end of your available DMEM.

$$
\text{Initial SP} = \text{DMEM_BASE} + \text{DMEM_SIZE}
$$

For example, if your DMEM size is 7KB (the `sw/coremark` example), and the Mach-V processor's DMEM base address is `0x10010000`, then the initial stack pointer should be set to:

```riscv
li sp, 0x10011C00  # 0x10010000 + 7 * 1024
```

---

### Compile and Load

After setting up the three files above, you can simply run the `make` command in the terminal while being in the application's directory. If everything is set up correctly, two hex files named `code.hex` and `data.hex` will be generated. Copy and paste the contents of `code.hex` into `AA_IROM.mem` and `data.hex` into `AA_DMEM.mem` in the Vivado project to load the program into the Mach-V processor.

To clean up the generated files, you can run `make clean`.

!!! success
    Now you are ready to write, compile, and run your software on the Mach-V processor! Feel free to move on to explore the existing software applications in the `sw/` directory.

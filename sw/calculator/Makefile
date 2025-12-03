# --- Toolchain Configuration ---
# Point this to your toolchain install
GCC_DIR = /opt/riscv
GCC_PREFIX = riscv32-unknown-elf-
GCC_NATIVE = $(GCC_DIR)/bin

# Use GCC as the driver for everything (including linking)
CC = $(GCC_NATIVE)/$(GCC_PREFIX)gcc
AS = $(GCC_NATIVE)/$(GCC_PREFIX)as
OBJDUMP = $(GCC_NATIVE)/$(GCC_PREFIX)objdump
OBJCOPY = $(GCC_NATIVE)/$(GCC_PREFIX)objcopy

# --- Flags ---
# Note: We include -lgcc at the end of the link step, 
# but GCC handles the path automatically.
CFLAGS = \
	-g \
	-O2 \
	-fno-stack-protector \
	-fno-builtin \
	-ffreestanding \
	-nostdlib \
	-nodefaultlibs \
	-nostartfiles \
	-mstrict-align \
	-march=rv32im \
	-mabi=ilp32 \
	-fno-jump-tables

ASFLAGS = -march=rv32im -mabi=ilp32

# --- Files ---
SRCS = uart_calculator.c
OBJS = $(SRCS:.c=.o)
CRTASM = crt.s
CRTOBJ = crt.o
LDSCRIPT = ld.script

# --- Targets ---

all: code.hex data.hex prog.dump

# 1. Compile C
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# 2. Assemble startup
$(CRTOBJ): $(CRTASM)
	$(AS) $(ASFLAGS) -c $< -o $@

# 3. Link (UPDATED)
# We use $(CC) instead of $(LD). 
# We also pass $(CFLAGS) so it knows the arch and to not use stdlibs.
prog.elf: $(CRTOBJ) $(OBJS) $(LDSCRIPT)
	$(CC) $(CFLAGS) -T $(LDSCRIPT) $(CRTOBJ) $(OBJS) -o prog.elf -lgcc

# 4. Dump for debugging
prog.dump: prog.elf
	$(OBJDUMP) -D prog.elf > prog.dump

# 5. Hex Generation
code.bin: prog.elf
	$(OBJCOPY) -O binary -j .text -j .text.startup prog.elf code.bin

code.hex: code.bin
	hexdump -v -e '1/4 "%08x\n"' code.bin > code.hex

data.bin: prog.elf
	$(OBJCOPY) -O binary -j .rodata -j .data -j .sdata -j .sbss -j .bss prog.elf data.bin

data.hex: data.bin
	hexdump -v -e '1/4 "%08x\n"' data.bin > data.hex

clean:
	rm -f *.o *.elf *.bin *.hex *.dump
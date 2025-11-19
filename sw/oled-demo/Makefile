# cross compiler
GCC_DIR = /opt/riscv
GCC_PREFIX = riscv32-unknown-elf-
GCC_NATIVE = $(GCC_DIR)/bin

CC = $(GCC_NATIVE)/$(GCC_PREFIX)gcc
AS = $(GCC_NATIVE)/$(GCC_PREFIX)as
LD = $(GCC_NATIVE)/$(GCC_PREFIX)ld
OBJDUMP = $(GCC_NATIVE)/$(GCC_PREFIX)objdump
OBJCOPY = $(GCC_NATIVE)/$(GCC_PREFIX)objcopy

CFLAGS = \
	-g \
	-O3 \
	-fno-stack-protector \
	-fno-zero-initialized-in-bss \
	-ffreestanding \
	-fno-builtin \
	-nostdlib \
	-nodefaultlibs \
	-nostartfiles \
	-mstrict-align \
	-march=rv32im \

ASFLAGS = \
  -march=rv32im \

LDFLAGS= \
    -static \

LIBC =
LIBGCC = \
  -L$(GCC_DIR)/lib/gcc/riscv32-unknown-elf/13.2.0 \
	-lgcc \
	-lgcov \
	-L$(GCC_DIR)/riscv32-unknown-elf/lib \
	-lm

# start up routine
CRTOBJ = crt.o
CRTASM = crt.s
LDSCRIPT = ld.script

# Coremark specific definition
ITERATIONS = 0
CLOCKS_PER_SEC = 100000000
FLAGS_STR = ""

CORE_FILES = \
	core_list_join.c \
	core_main.c \
	core_matrix.c \
	core_state.c \
	core_util.c \
	oled.c \

PORT_DIR = barebones
PORT_FILES = \
	$(PORT_DIR)/core_portme.c \
	$(PORT_DIR)/ee_printf.c \

SRCS = $(CORE_FILES) $(PORT_FILES)
OBJS = $(SRCS:.c=.o)

XCFLAGS = \
	-g \
	-DITERATIONS=$(ITERATIONS) \
	-DCLOCKS_PER_SEC=$(CLOCKS_PER_SEC) \
	-I ./ \
	-I $(PORT_DIR) \
	-DFLAGS_STR=\"$(FLAGS_STR)\" \

all: code.hex data.hex prog.dump

%.o: %.c Makefile
	$(CC) $(CFLAGS) $(XCFLAGS) -o $@ -c $<

prog.elf: $(OBJS) $(CRTOBJ) Makefile
	$(LD) $(CRTOBJ) $(OBJS) $(LIBGCC) $(LIBC) -T$(LDSCRIPT) $(LDFLAGS) -o prog.elf

prog.dump: prog.elf
	$(OBJDUMP) -D prog.elf > prog.dump

prog.bin: prog.elf
	$(OBJCOPY) -O binary prog.elf prog.bin

# Create code.hex (for IROM at 0x0100)
code.elf: prog.elf
	$(OBJCOPY) -j .text -j .text.startup prog.elf code.elf

code.bin: code.elf
	$(OBJCOPY) -O binary code.elf code.bin

code.hex: code.bin
	hexdump -v -e '1/4 "%08x\n"' code.bin > code.hex
	

# Create data.hex (for DMEM at 0x6100)
data.elf: prog.elf
	$(OBJCOPY) -j .rodata -j .rodata.str1.4 -j .data -j .sdata -j .bss -j .comment prog.elf data.elf

data.bin: data.elf
	$(OBJCOPY) -O binary data.elf data.bin

data.hex: data.bin
	hexdump -v -e '1/4 "%08x\n"' data.bin > data.hex

$(CRTOBJ): $(CRTASM)
	$(AS) $(ASFLAGS) -o $@ -c $<

.PHONY: clean
clean:
	rm -f $(OBJS) crt.o prog.elf prog.dump code.elf code.bin code.hex data.elf data.bin data.hex data_temp.bin code.s data.s
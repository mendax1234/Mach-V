# CG3207 Lab 4 UART Based Arithmetic Emulator - Enhanced with Byte/Halfword Operations
# ----------------------------------------------------------------
# Command Encoding (single ASCII character):
#
# Arithmetic Operations:
#   'a' -> ADD    (t4 = t2 + t3)
#   's' -> SUB    (t4 = t2 - t3)
#
# Logical Operations:
#   'x' -> XOR    (t4 = t2 ^ t3)
#   'o' -> OR     (t4 = t2 | t3)
#   'c' -> AND    (t4 = t2 & t3)
#
# Comparison Operations:
#   'l' -> SLT    (t4 = (t2 < t3) signed ? 1 : 0)
#   'u' -> SLTU   (t4 = (t2 < t3) unsigned ? 1 : 0)
#
# Shift Operations:
#   'L' -> SLL    (t4 = t2 << (t3 & 0x1F))
#   'R' -> SRL    (t4 = t2 >> (t3 & 0x1F) logical)
#   'A' -> SRA    (t4 = t2 >> (t3 & 0x1F) arithmetic)
#
# Multiply Operations:
#   'm' -> MUL    (t4 = lower 32 bits of t2 * t3)
#   'H' -> MULH   (t4 = upper 32 bits of t2 * t3, signed)
#   'h' -> MULHU  (t4 = upper 32 bits of t2 * t3, unsigned)
#
# Divide Operations:
#   'd' -> DIV    (t4 = t2 / t3, signed)
#   'D' -> DIVU   (t4 = t2 / t3, unsigned)
#   'r' -> REM    (t4 = t2 % t3, signed)
#   'M' -> REMU   (t4 = t2 % t3, unsigned)
#
# Branch Operations:
#   'b' -> BLT    (t4 = (t2 < t3) signed ? 1 : 0)
#   'B' -> BGE    (t4 = (t2 >= t3) signed ? 1 : 0)
#   'n' -> BLTU   (t4 = (t2 < t3) unsigned ? 1 : 0)
#   'N' -> BGEU   (t4 = (t2 >= t3) unsigned ? 1 : 0)
#
# Byte/Halfword Load Operations:
#   '1' -> LB     Load byte signed from test_data[t2], sign-extend to 32-bit
#   '2' -> LBU    Load byte unsigned from test_data[t2], zero-extend to 32-bit
#   '3' -> LH     Load halfword signed from test_data[t2], sign-extend to 32-bit
#   '4' -> LHU    Load halfword unsigned from test_data[t2], zero-extend to 32-bit
#
# Byte/Halfword Store Operations:
#   '5' -> SB     Store low byte of t3 to scratch_mem[t2], then load word to verify
#   '6' -> SH     Store low halfword of t3 to scratch_mem[t2], then load word to verify
#
# For loads: t2 is byte offset into test_data (0-15)
# For stores: t2 is byte offset into scratch_mem (0-3), t3 is data to store
#
# test_data contains: 0x12345678, 0x9ABCDEF0, 0xAABBCCDD, 0xEEFF0011
# scratch_mem: writable area initialized to 0x00000000
#
# Protocol: 1 command byte + 4 bytes operand1 + 4 bytes operand2 (MSB first)
#
# **ENHANCEMENT**: The UART reading routines now use LBU instruction instead of
#                  LW + ANDI to demonstrate byte load functionality in practice!
# ----------------------------------------------------------------

.eqv MMIO_BASE          0xFFFF0000
.eqv UART_RX_VALID_OFF  0x00
.eqv UART_RX_OFF        0x04
.eqv UART_TX_READY_OFF  0x08
.eqv UART_TX_OFF        0x0C
.eqv SEVENSEG_OFF       0x80
.eqv LSB_MASK           0x01

.data
# Test data for load operations (16 bytes = 4 words)
# Byte layout: [78][56][34][12] [F0][DE][BC][9A] [DD][CC][BB][AA] [11][00][FF][EE]
test_data:
    .word 0x12345678    # offset 0-3
    .word 0x9ABCDEF0    # offset 4-7
    .word 0xAABBCCDD    # offset 8-11
    .word 0xEEFF0011    # offset 12-15

# Scratch memory for store operations (1 word)
scratch_mem:
    .word 0x00000000

.text
main:
    # Initialization of MMIO addresses
    li   s0, MMIO_BASE
    addi s1, s0, UART_RX_VALID_OFF
    addi s2, s0, UART_RX_OFF
    addi s3, s0, UART_TX_READY_OFF
    addi s4, s0, UART_TX_OFF
    addi s5, s0, SEVENSEG_OFF
    li   s7, LSB_MASK
    
    # Load addresses of test data and scratch memory
    la   s8, test_data      # s8 = base address of test data
    la   s9, scratch_mem    # s9 = base address of scratch memory

# Main processing loop
loop:
# Read command byte
READ_CMD:
    lw   t0, 0(s1)
    and  t0, t0, s7
    beqz t0, READ_CMD
    lbu  t1, 0(s2)          # load byte unsigned from UART_RX (automatically zero-extends)

# Echo command back
ECHO_CMD:
    mv   a0, t1
    jal  ECHO_BYTE

# Read Operand 1 (4 bytes, MSB first)
    li   t5, 4
    li   t2, 0

READ_OP1_LOOP:
    lw   t0, 0(s1)
    and  t0, t0, s7
    beqz t0, READ_OP1_LOOP
    lbu  t6, 0(s2)          # load byte unsigned (no need for ANDI anymore!)
    # Echo the received byte back
    mv   a0, t6
    jal  ECHO_BYTE
    # Build the 32-bit number
    slli t2, t2, 8
    or   t2, t2, t6
    addi t5, t5, -1
    bnez t5, READ_OP1_LOOP

# Read Operand 2 (4 bytes, MSB first)
    li   t5, 4
    li   t3, 0

READ_OP2_LOOP:
    lw   t0, 0(s1)
    and  t0, t0, s7
    beqz t0, READ_OP2_LOOP
    lbu  t6, 0(s2)          # load byte unsigned (cleaner code!)
    # Echo the received byte back
    mv   a0, t6
    jal  ECHO_BYTE
    # Build the 32-bit number
    slli t3, t3, 8
    or   t3, t3, t6
    addi t5, t5, -1
    bnez t5, READ_OP2_LOOP

# Decode and execute command
CMD_CHECK:
    # Arithmetic Operations
    li   t0, 'a'
    beq  t1, t0, DO_ADD
    li   t0, 's'
    beq  t1, t0, DO_SUB
    
    # Logical Operations
    li   t0, 'x'
    beq  t1, t0, DO_XOR
    li   t0, 'o'
    beq  t1, t0, DO_OR
    li   t0, 'c'
    beq  t1, t0, DO_AND
    
    # Comparison Operations
    li   t0, 'l'
    beq  t1, t0, DO_SLT
    li   t0, 'u'
    beq  t1, t0, DO_SLTU
    
    # Shift Operations
    li   t0, 'L'
    beq  t1, t0, DO_SLL
    li   t0, 'R'
    beq  t1, t0, DO_SRL
    li   t0, 'A'
    beq  t1, t0, DO_SRA
    
    # Multiply Operations
    li   t0, 'm'
    beq  t1, t0, DO_MUL
    li   t0, 'H'
    beq  t1, t0, DO_MULH
    li   t0, 'h'
    beq  t1, t0, DO_MULHU
    
    # Divide Operations
    li   t0, 'd'
    beq  t1, t0, DO_DIV
    li   t0, 'D'
    beq  t1, t0, DO_DIVU
    li   t0, 'r'
    beq  t1, t0, DO_REM
    li   t0, 'M'
    beq  t1, t0, DO_REMU
    
    # Branch Operations
    li   t0, 'b'
    beq  t1, t0, DO_BLT
    li   t0, 'B'
    beq  t1, t0, DO_BGE
    li   t0, 'n'
    beq  t1, t0, DO_BLTU
    li   t0, 'N'
    beq  t1, t0, DO_BGEU
    
    # Byte/Halfword Load Operations
    li   t0, 0x31           # ASCII '1'
    beq  t1, t0, DO_LB
    li   t0, 0x32           # ASCII '2'
    beq  t1, t0, DO_LBU
    li   t0, 0x33           # ASCII '3'
    beq  t1, t0, DO_LH
    li   t0, 0x34           # ASCII '4'
    beq  t1, t0, DO_LHU
    
    # Byte/Halfword Store Operations
    li   t0, 0x35           # ASCII '5'
    beq  t1, t0, DO_SB
    li   t0, 0x36           # ASCII '6'
    beq  t1, t0, DO_SH
    
    j    loop

# ARITHMETIC OPERATIONS
DO_ADD:
    add  t4, t2, t3
    sw   t4, 0(s5)
    j    loop

DO_SUB:
    sub  t4, t2, t3
    sw   t4, 0(s5)
    j    loop

# LOGICAL OPERATIONS
DO_XOR:
    xor  t4, t2, t3
    sw   t4, 0(s5)
    j    loop

DO_OR:
    or   t4, t2, t3
    sw   t4, 0(s5)
    j    loop

DO_AND:
    and  t4, t2, t3
    sw   t4, 0(s5)
    j    loop

# COMPARISON OPERATIONS
DO_SLT:
    slt  t4, t2, t3
    sw   t4, 0(s5)
    j    loop

DO_SLTU:
    sltu t4, t2, t3
    sw   t4, 0(s5)
    j    loop

# SHIFT OPERATIONS
DO_SLL:
    andi t0, t3, 0x1F
    sll  t4, t2, t0
    sw   t4, 0(s5)
    j    loop

DO_SRL:
    andi t0, t3, 0x1F
    srl  t4, t2, t0
    sw   t4, 0(s5)
    j    loop

DO_SRA:
    andi t0, t3, 0x1F
    sra  t4, t2, t0
    sw   t4, 0(s5)
    j    loop

# MULTIPLY OPERATIONS
DO_MUL:
    mul  t4, t2, t3
    sw   t4, 0(s5)
    j    loop

DO_MULH:
    mulh t4, t2, t3
    sw   t4, 0(s5)
    j    loop

DO_MULHU:
    mulhu t4, t2, t3
    sw   t4, 0(s5)
    j    loop

# DIVIDE OPERATIONS
DO_DIV:
    beqz t3, DIV_ZERO
    div  t4, t2, t3
    sw   t4, 0(s5)
    j    loop

DO_DIVU:
    beqz t3, DIV_ZERO
    divu t4, t2, t3
    sw   t4, 0(s5)
    j    loop

DO_REM:
    beqz t3, DIV_ZERO
    rem  t4, t2, t3
    sw   t4, 0(s5)
    j    loop

DO_REMU:
    beqz t3, DIV_ZERO
    remu t4, t2, t3
    sw   t4, 0(s5)
    j    loop

# BRANCH OPERATIONS
DO_BLT:
    blt  t2, t3, BRANCH_TAKEN
    li   t4, 0
    sw   t4, 0(s5)
    j    loop

DO_BGE:
    bge  t2, t3, BRANCH_TAKEN
    li   t4, 0
    sw   t4, 0(s5)
    j    loop

DO_BLTU:
    bltu t2, t3, BRANCH_TAKEN
    li   t4, 0
    sw   t4, 0(s5)
    j    loop

DO_BGEU:
    bgeu t2, t3, BRANCH_TAKEN
    li   t4, 0
    sw   t4, 0(s5)
    j    loop

BRANCH_TAKEN:
    li   t4, 1
    sw   t4, 0(s5)
    j    loop

# BYTE/HALFWORD LOAD OPERATIONS
# t2 = byte offset into test_data (0-15)
# Loads from test_data and displays result

# LB - Load Byte Signed
# Example: offset=0 loads 0x78, sign-extends to 0x00000078
#          offset=5 loads 0xDE, sign-extends to 0xFFFFFFDE
DO_LB:
    add  t0, s8, t2         # t0 = test_data + offset
    lb   t4, 0(t0)          # load byte with sign extension
    sw   t4, 0(s5)          # display result
    j    loop

# LBU - Load Byte Unsigned
# Example: offset=5 loads 0xDE, zero-extends to 0x000000DE
DO_LBU:
    add  t0, s8, t2         # t0 = test_data + offset
    lbu  t4, 0(t0)          # load byte with zero extension
    sw   t4, 0(s5)          # display result
    j    loop

# LH - Load Halfword Signed
# Example: offset=0 loads 0x5678, sign-extends to 0x00005678
#          offset=6 loads 0x9ABC, sign-extends to 0xFFFF9ABC
DO_LH:
    add  t0, s8, t2         # t0 = test_data + offset
    lh   t4, 0(t0)          # load halfword with sign extension
    sw   t4, 0(s5)          # display result
    j    loop

# LHU - Load Halfword Unsigned
# Example: offset=6 loads 0x9ABC, zero-extends to 0x00009ABC
DO_LHU:
    add  t0, s8, t2         # t0 = test_data + offset
    lhu  t4, 0(t0)          # load halfword with zero extension
    sw   t4, 0(s5)          # display result
    j    loop

# BYTE/HALFWORD STORE OPERATIONS
# t2 = byte offset into scratch_mem (0-3 for bytes, 0 or 2 for halfwords)
# t3 = data to store
# After storing, reads back the entire word to verify

# SB - Store Byte
# Example: offset=0, data=0xAB -> scratch becomes 0x??????AB
#          offset=2, data=0xCD -> scratch becomes 0x??CD????
DO_SB:
    # First, clear scratch_mem
    sw   zero, 0(s9)
    # Store byte
    add  t0, s9, t2         # t0 = scratch_mem + offset
    sb   t3, 0(t0)          # store low byte of t3
    # Read back entire word to verify
    lw   t4, 0(s9)          # load entire word
    sw   t4, 0(s5)          # display result
    j    loop

# SH - Store Halfword
# Example: offset=0, data=0xABCD -> scratch becomes 0x????ABCD
#          offset=2, data=0xEF01 -> scratch becomes 0xEF01????
DO_SH:
    # First, clear scratch_mem
    sw   zero, 0(s9)
    # Store halfword
    add  t0, s9, t2         # t0 = scratch_mem + offset
    sh   t3, 0(t0)          # store low halfword of t3
    # Read back entire word to verify
    lw   t4, 0(s9)          # load entire word
    sw   t4, 0(s5)          # display result
    j    loop

# ERROR HANDLING
DIV_ZERO:
    li   t4, 0xFFFFFFFF
    sw   t4, 0(s5)
    j    loop

# Subroutine: ECHO_BYTE
ECHO_BYTE:
    lw   t0, 0(s3)
    and  t0, t0, s7
    beqz t0, ECHO_BYTE
    sb   a0, 0(s4)          # store byte to UART_TX (more efficient!)
    ret
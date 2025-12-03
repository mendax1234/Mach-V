#include <stdint.h>

// ============================================================================
// MMIO Definitions
// ============================================================================
#define MMIO_BASE 0xFFFF0000
#define UART_RX_VALID_OFF 0x00
#define UART_RX_DATA_OFF 0x04
#define UART_TX_READY_OFF 0x08
#define UART_TX_DATA_OFF 0x0C
#define SEVENSEG_OFF 0x80

// Volatile pointers to prevent compiler optimization of MMIO accesses
#define UART_RX_VALID ((volatile uint32_t *)(MMIO_BASE + UART_RX_VALID_OFF))
#define UART_RX_DATA ((volatile uint8_t *)(MMIO_BASE + UART_RX_DATA_OFF)) // Byte access (LBU)
#define UART_TX_READY ((volatile uint32_t *)(MMIO_BASE + UART_TX_READY_OFF))
#define UART_TX_DATA ((volatile uint8_t *)(MMIO_BASE + UART_TX_DATA_OFF))
#define SEVENSEG ((volatile uint32_t *)(MMIO_BASE + SEVENSEG_OFF))

// ============================================================================
// Data Sections
// ============================================================================
// Matches .data section in assembly
uint32_t test_data[4] = {
    0x12345678,
    0x9ABCDEF0,
    0xAABBCCDD,
    0xEEFF0011};

uint32_t scratch_mem[1] = {0x00000000};

// ============================================================================
// Helper Functions
// ============================================================================

// Reads a single byte from UART (Blocking)
uint8_t uart_read_byte()
{
    // Wait until bit 0 of RX_VALID is 1
    while ((*UART_RX_VALID & 1) == 0)
        ;
    return *UART_RX_DATA;
}

// Writes a single byte to UART (Blocking)
void uart_write_byte(uint8_t c)
{
    // Wait until bit 0 of TX_READY is 1
    while ((*UART_TX_READY & 1) == 0)
        ;
    *UART_TX_DATA = c;
}

// Reads 4 bytes (MSB first) to construct a 32-bit integer
uint32_t read_operand()
{
    uint32_t result = 0;
    for (int i = 0; i < 4; i++)
    {
        uint8_t byte = uart_read_byte();
        uart_write_byte(byte); // Echo the byte
        result = (result << 8) | byte;
    }
    return result;
}

// ============================================================================
// Main Loop
// ============================================================================
int main()
{
    uint8_t cmd;
    uint32_t s10, s11, t4;

    // Pointers for Load/Store operations
    uint8_t *test_data_byte_ptr = (uint8_t *)test_data;
    uint8_t *scratch_mem_byte_ptr = (uint8_t *)scratch_mem;

    while (1)
    {
        // 1. Read Command
        cmd = uart_read_byte();

        // 2. Echo Command
        uart_write_byte(cmd);

        // 3. Read Operands
        s10 = read_operand();
        s11 = read_operand();

        t4 = 0; // Default result

        // 4. Execute Command
        switch (cmd)
        {
        // Arithmetic
        case 'a':
            t4 = s10 + s11;
            break; // ADD
        case 's':
            t4 = s10 - s11;
            break; // SUB

        // Logical
        case 'x':
            t4 = s10 ^ s11;
            break; // XOR
        case 'o':
            t4 = s10 | s11;
            break; // OR
        case 'c':
            t4 = s10 & s11;
            break; // AND

        // Comparison
        case 'l':
            t4 = ((int32_t)s10 < (int32_t)s11) ? 1 : 0;
            break; // SLT (Signed)
        case 'u':
            t4 = ((uint32_t)s10 < (uint32_t)s11) ? 1 : 0;
            break; // SLTU (Unsigned)

        // Shift
        case 'L':
            t4 = s10 << (s11 & 0x1F);
            break; // SLL
        case 'R':
            t4 = (uint32_t)s10 >> (s11 & 0x1F);
            break; // SRL (Logical)
        case 'A':
            t4 = (int32_t)s10 >> (s11 & 0x1F);
            break; // SRA (Arithmetic)

        // Multiply
        case 'm':
            t4 = s10 * s11;
            break; // MUL (Lower 32)
        case 'H':
            t4 = (uint32_t)(((int64_t)(int32_t)s10 * (int64_t)(int32_t)s11) >> 32);
            break; // MULH (Signed Upper)
        case 'h':
            t4 = (uint32_t)(((uint64_t)s10 * (uint64_t)s11) >> 32);
            break; // MULHU (Unsigned Upper)

        // Divide (Handle divide by zero by returning -1/0xFFFFFFFF)
        case 'd': // DIV
            if (s11 == 0)
                t4 = 0xFFFFFFFF;
            else
                t4 = (int32_t)s10 / (int32_t)s11;
            break;
        case 'D': // DIVU
            if (s11 == 0)
                t4 = 0xFFFFFFFF;
            else
                t4 = (uint32_t)s10 / (uint32_t)s11;
            break;
        case 'r': // REM
            if (s11 == 0)
                t4 = 0xFFFFFFFF;
            else
                t4 = (int32_t)s10 % (int32_t)s11;
            break;
        case 'M': // REMU
            if (s11 == 0)
                t4 = 0xFFFFFFFF;
            else
                t4 = (uint32_t)s10 % (uint32_t)s11;
            break;

        // Branches (Emulate result)
        case 'b':
            t4 = ((int32_t)s10 < (int32_t)s11) ? 1 : 0;
            break; // BLT
        case 'B':
            t4 = ((int32_t)s10 >= (int32_t)s11) ? 1 : 0;
            break; // BGE
        case 'n':
            t4 = ((uint32_t)s10 < (uint32_t)s11) ? 1 : 0;
            break; // BLTU
        case 'N':
            t4 = ((uint32_t)s10 >= (uint32_t)s11) ? 1 : 0;
            break; // BGEU

        // Load Operations (from test_data)
        // s10 is byte offset
        case '1':                                                // LB
            t4 = (int32_t)(int8_t)test_data_byte_ptr[s10 & 0xF]; // Mask to safe range logic if needed
            break;
        case '2': // LBU
            t4 = (uint32_t)test_data_byte_ptr[s10 & 0xF];
            break;
        case '3': // LH
        {
            // Unaligned access handling if necessary, but standard cast here:
            int16_t val = *(int16_t *)(test_data_byte_ptr + (s10 & 0xE));
            t4 = (int32_t)val;
        }
        break;
        case '4': // LHU
        {
            uint16_t val = *(uint16_t *)(test_data_byte_ptr + (s10 & 0xE));
            t4 = (uint32_t)val;
        }
        break;

        // Store Operations (to scratch_mem)
        // s10 is offset, s11 is data
        case '5':               // SB
            scratch_mem[0] = 0; // Clear first (as per asm logic)
            scratch_mem_byte_ptr[s10 & 0x3] = (uint8_t)(s11 & 0xFF);
            t4 = scratch_mem[0]; // Load word to verify
            break;
        case '6': // SH
            scratch_mem[0] = 0;
            *(uint16_t *)(scratch_mem_byte_ptr + (s10 & 0x2)) = (uint16_t)(s11 & 0xFFFF);
            t4 = scratch_mem[0];
            break;

        default:
            break;
        }

        // 5. Output Result to 7-Segment
        *SEVENSEG = t4;
    }

    return 0;
}

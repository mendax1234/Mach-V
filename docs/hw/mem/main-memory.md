# Main Memory

| Address Range              | Name                        | Permissions        | Description |
|----------------------------|-----------------------------|--------------------|-------------|
| `0x00400000 – 0x00407FFF` | IROM (Instruction Memory)   | RO (Read-Only)     | Capacity: 8,192 words (32 KB). Based on `IROM_DEPTH_BITS = 15`. |
| `0x10010000 – 0x10013FFF` | DMEM (Data Memory)          | RW (Read-Write)    | Capacity: 4,096 words (16 KB). Used for storing constants and variables. Based on `DMEM_DEPTH_BITS = 14`. |

!!! warning "Addressing Constraints"
    Accesses must be aligned to 4-byte boundaries.
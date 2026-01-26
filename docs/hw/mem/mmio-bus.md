# Memory-Mapped Peripherals (MMIO)

All peripherals are mapped to the upper memory range starting at `0xFFFFxxxx`.

## Communication (UART)

| Address      | Register Name | Perms | Description                                                                                                                  |
| ------------ | ------------- | ----- | ---------------------------------------------------------------------------------------------------------------------------- |
| `0xFFFF0000` | UART_RX_VALID | RO    | Receive Status. Data is valid to read from `UART_RX` only when the LSB (Least Significant Bit) of this register is set to 1. |
| `0xFFFF0004` | UART_RX       | RO    | Receive Data. Reads input from the keyboard. Only the LSByte (lowest 8 bits) contains valid data.                            |
| `0xFFFF0008` | UART_TX_READY | RO    | Transmit Status. Data is safe to write to `UART_TX` only when the LSB of this register is set to 1.                          |
| `0xFFFF000C` | UART_TX       | WO    | Transmit Data. Sends output to the display/console. Only the LSByte is writeable.                                            |

## On-Board I/O (GPIO)

| Address      | Register Name | Perms | Description                       |
| ------------ | ------------- | ----- | --------------------------------- |
| `0xFFFF0060` | LED           | WO    | LED control register              |
| `0xFFFF0064` | DIP           | RO    | DIP switch input register         |
| `0xFFFF0068` | PB            | RO    | Push button input register        |
| `0xFFFF0080` | SEVENSEG      | WO    | 7-segment display output register |

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

## Sensor & Display Modules

| Address      | Register Name | Perms | Description                                                               |
| ------------ | ------------- | ----- | ------------------------------------------------------------------------- |
| `0xFFFF0020` | OLED_COL      | WO    | Sets the OLED pixel column index (0 – 95).                                |
| `0xFFFF0024` | OLED_ROW      | WO    | Sets the OLED pixel row index (0 – 63).                                   |
| `0xFFFF0028` | OLED_DATA     | WO    | Writes data to the pixel. Format depends on `OLED_CTRL`.                  |
| `0xFFFF002C` | OLED_CTRL     | WO    | Controls OLED data format and operation modes.                            |
| `0xFFFF0040` | ACCEL_DATA    | RO    | Reads accelerometer data (refer to peripherals documentation for format). |
| `0xFFFF0044` | ACCEL_DREADY  | RO    | Data Ready. LSB is set when a new reading is available.                   |

## System Counters

| Address      | Register Name | Perms | Description                                                    |
| ------------ | ------------- | ----- | -------------------------------------------------------------- |
| `0xFFFF00A0` | CYCLECOUNT    | RO    | Returns the number of clock cycles elapsed since system reset. |
`timescale 1ns / 1ps

module uart_top_sim ();
    reg  [15:0] DIP = 0;
    reg  [ 2:0] PB = 0;
    wire [ 7:0] LED_OUT;
    wire [ 6:0] LED_PC;
    wire [31:0] SEVENSEGHEX;

    // Updated UART Ports
    wire [ 7:0] UART_TX_DATA;
    reg         UART_TX_READY = 1'b1;
    wire        UART_TX_VALID;
    reg  [ 7:0] UART_RX_DATA;
    reg         UART_RX_VALID;
    wire        UART_RX_ACK;

    // Updated OLED Ports
    wire        OLED_WRITE;
    wire [ 6:0] OLED_COL;
    wire [ 5:0] OLED_ROW;
    wire [23:0] OLED_PIXEL_DATA;

    // Updated Accel Ports
    reg  [31:0] ACCEL_DATA = 32'd0;
    wire        ACCEL_READY = 1'b0;  // Note: You had this as ACCEL_DReady previously

    reg         RESET = 0;
    reg         CLK = 0;

    Wrapper dut (
        .DIP        (DIP),
        .PB         (PB),
        .LED_OUT    (LED_OUT),
        .LED_PC     (LED_PC),
        .SEVENSEGHEX(SEVENSEGHEX),

        // UART
        .UART_TX_DATA (UART_TX_DATA),
        .UART_TX_READY(UART_TX_READY),
        .UART_TX_VALID(UART_TX_VALID),
        .UART_RX_DATA (UART_RX_DATA),
        .UART_RX_VALID(UART_RX_VALID),
        .UART_RX_ACK  (UART_RX_ACK),

        // OLED
        .OLED_WRITE     (OLED_WRITE),
        .OLED_COL       (OLED_COL),
        .OLED_ROW       (OLED_ROW),
        .OLED_PIXEL_DATA(OLED_PIXEL_DATA),

        // Accel
        .ACCEL_DATA (ACCEL_DATA),
        .ACCEL_READY(ACCEL_READY),

        .RESET(RESET),
        .CLK  (CLK)
    );

    //clock
    always #5 CLK = ~CLK;

    // uart input
    task send_uart;
        input [7:0] cmd;
        input [31:0] op1;
        input [31:0] op2;
        integer       i;
        reg     [7:0] byte_array[0:8];  // 9 bytes: 1 cmd + 8 data
        begin
            // --- Construct full 9-byte command packet (MSB first) ---
            byte_array[0] = cmd;
            {byte_array[1], byte_array[2], byte_array[3], byte_array[4]} = op1[31:0];
            {byte_array[5], byte_array[6], byte_array[7], byte_array[8]} = op2[31:0];

            // send byte by byte
            for (i = 0; i < 9; i = i + 1) begin
                UART_RX_DATA = byte_array[i];  // UPDATED NAME
                UART_RX_VALID = 1;  // UPDATED NAME
                // Wait until CPU acknowledges (reads from UART_RX)
                wait (UART_RX_ACK == 1);  // UPDATED NAME
                UART_RX_VALID = 0;  // UPDATED NAME
                // Wait until CPU clears ack before sending next byte
                wait (UART_RX_ACK == 0);  // UPDATED NAME
                // small inter-byte delay
                #500;
            end

            // gap before next command
            #700;
        end
    endtask

    initial begin
        UART_RX_DATA = 8'd0;
        UART_RX_VALID = 0;
        RESET = 1;
        #50;
        RESET = 0;

        #100;

        // ---- Test SUB 9 - 5 ----
        send_uart("s", 32'd9, 32'd5);
        #150;

        // ---- Test DIV 14 / 2 ----
        send_uart("d", 32'd14, 32'd2);
        #150;

        // ---- Test DIVU 0x80000000 / 2 ----
        send_uart("D", 32'h80000000, 32'd2);
        #150;

        // ---- Test REM -14 % 3  ----
        send_uart("r", -32'd14, 32'd3);
        #150;

        // ---- Test REMU 0xFFFFFFF2 / 5 ----
        send_uart("M", -32'd14, 32'd5);  // Passing -14 creates 0xFFFFFFF2 bit pattern
        #150;

        // ---- Test REM 14 % 3 ----
        send_uart("r", 32'd14, -32'd3);
        #150;

        // ---- Test MUL 6 * 7 ----
        send_uart("m", 32'd6, 32'd7);
        #150;

        // ---- Test MULH 0x400000000 * 4 ----
        send_uart("H", 32'h40000000, 32'd4);
        #150;

        // ---- Test MULHU 0x80000000 * 2 ----
        send_uart("h", 32'h80000000, 32'd2);
        #150;

        // ---- Test MULH -1 * -1 ----
        send_uart("H", 32'hFFFFFFFF, 32'hFFFFFFFF);
        #150;

        // ---- Test SB at Offset 0 ----
        // Command '5', Offset 0, Data 0xAB
        send_uart("5", 32'd0, 32'h000000AB);
        #150;

        // ---- Test SB at Offset 2 ----
        // Command '5', Offset 2, Data 0xCD
        send_uart("5", 32'd2, 32'h000000CD);
        #150;

        $display("All tests transmitted! Please check SEVENSEGHEX in waveforms.");
        $stop;
    end

endmodule

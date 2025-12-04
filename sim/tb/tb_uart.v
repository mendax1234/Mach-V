`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.10.2025 11:35:57
// Design Name: 
// Module Name: uart_top_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_top_sim(
);
    reg  [15:0] DIP = 0;
    reg  [2:0]  PB  = 0;
    wire [7:0]  LED_OUT;
    wire [6:0]  LED_PC;
    wire [31:0] SEVENSEGHEX;
    wire [7:0]  UART_TX;
    reg         UART_TX_ready = 1'b1;
    wire        UART_TX_valid;
    reg  [7:0]  UART_RX;
    reg         UART_RX_valid;
    wire        UART_RX_ack;
    wire        OLED_Write;
    wire [6:0]  OLED_Col;
    wire [5:0]  OLED_Row;
    wire [23:0] OLED_Data;
    reg  [31:0] ACCEL_Data = 32'd0;
    wire        ACCEL_DReady = 1'b0;
    reg         RESET = 0;
    reg         CLK   = 0;

    Wrapper dut (
        .DIP(DIP),
        .PB(PB),
        .LED_OUT(LED_OUT),
        .LED_PC(LED_PC),
        .SEVENSEGHEX(SEVENSEGHEX),
        .UART_TX(UART_TX),
        .UART_TX_ready(UART_TX_ready),
        .UART_TX_valid(UART_TX_valid),
        .UART_RX(UART_RX),
        .UART_RX_valid(UART_RX_valid),
        .UART_RX_ack(UART_RX_ack),
        .OLED_Write(OLED_Write),
        .OLED_Col(OLED_Col),
        .OLED_Row(OLED_Row),
        .OLED_Data(OLED_Data),
        .ACCEL_Data(ACCEL_Data),
        .ACCEL_DReady(ACCEL_DReady),
        .RESET(RESET),
        .CLK(CLK)
    );
     
    //clock
    always #5 CLK = ~CLK;

    // uart input
    task send_uart;
        input [7:0] cmd;
        input [31:0] op1;
        input [31:0] op2;
        integer i;
        reg [7:0] byte_array [0:8]; // 9 bytes: 1 cmd + 8 data
        begin
            // --- Construct full 9-byte command packet (MSB first) ---
            byte_array[0] = cmd;
            {byte_array[1], byte_array[2], byte_array[3], byte_array[4]} = op1[31:0];
            {byte_array[5], byte_array[6], byte_array[7], byte_array[8]} = op2[31:0];
     
            // send byte by byte
            for (i = 0; i < 9; i = i + 1) begin
                UART_RX = byte_array[i];
                UART_RX_valid = 1;
                // Wait until CPU acknowledges (reads from UART_RX)
                wait (UART_RX_ack == 1);
                UART_RX_valid = 0;
                // Wait until CPU clears ack before sending next byte
                wait (UART_RX_ack == 0);
                // small inter-byte delay
                #500;
            end
     
            // gap before next command
            #700;
        end
    endtask


     
    initial begin
        UART_RX = 8'd0;
        UART_RX_valid = 0;
        RESET = 1; #50; RESET = 0;

        #100;
        
//        // ---- test subtract 9 - 5 ----
//        send_uart("s", 32'd9, 32'd5);
//        #150;
//        $display("SUB 9-5 = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);

        // ---- test divide 14 / 2 ----
        send_uart("d", 32'd14, 32'd2);
        #150;
        $display("DIV 14 / 2 = 0x%h (Expect 0x00000007)", dut.ComputeResult);
        
        // ---- Test DIVU (Unsigned Division) ----
        send_uart("D", 32'h80000000, 32'd2);
        #150;
        $display("DIVU 0x80000000 / 2 = 0x%h (Expect 0x40000000)", dut.ComputeResult);


        // ---- Test REM (Signed Remainder) ----
        // Scenario: -14 % 3
        // Math: -14 = (-4 * 3) - 2. The remainder matches the sign of the Dividend (Op1).
        // Op1: -14 (0xFFFFFFF2)
        // Op2: 3
        // Result: -2 (0xFFFFFFFE)
        send_uart("r", -32'd14, 32'd3);
        #150;
        $display("REM -14 %% 3 = %0d (Expect -2, Hex: FFFFFFFE)", $signed(dut.ComputeResult));


        // ---- Test REMU (Unsigned Remainder) ----
        // Scenario: 0xFFFFFFF2 (Large Positive) % 5
        // Unsigned Value of 0xFFFFFFF2 is 4,294,967,282.
        // Math: 4,294,967,282 / 5 = 858,993,456 with a remainder of 2.
        send_uart("M", -32'd14, 32'd5); // Passing -14 creates 0xFFFFFFF2 bit pattern
        #150;
        $display("REMU 0xFFFFFFF2 %% 5 = %0d (Expect 2)", dut.ComputeResult);


        // ---- Optional: REM (Sign Check 2) ----
        // Scenario: 14 % -3
        // Math: 14 = (-4 * -3) + 2. Remainder should be positive (matches Dividend).
        send_uart("r", 32'd14, -32'd3);
        #150;
        $display("REM 14 %% -3 = %0d (Expect 2)", $signed(dut.ComputeResult));
        
        // ---- test MUL (Lower 32 bits) ----
        send_uart("m", 32'd6, 32'd7);
        #150;
        $display("MUL 6*7 = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);

        // ---- test MULH (Signed High 32 bits) ----
        // 0x40000000 (1,073,741,824) * 4 = 4,294,967,296
        // Result in hex is 0x1_00000000. 
        // Lower 32 bits = 0, Upper 32 bits = 1.
        send_uart("H", 32'h40000000, 32'd4);
        #150;
        $display("MULH (Signed) 0x40000000 * 4 = %0d (Expect 1)", dut.ComputeResult);

        // ---- test MULHU (Unsigned High 32 bits) ----
        // 0x80000000 (2,147,483,648) * 2 = 4,294,967,296
        // Result in hex is 0x1_00000000.
        // Upper 32 bits = 1.
        send_uart("h", 32'h80000000, 32'd2);
        #150;
        $display("MULHU (Unsigned) 0x80000000 * 2 = %0d (Expect 1)", dut.ComputeResult);

        // ---- test MULH Negative Case ----
        // -1 (0xFFFFFFFF) * -1 (0xFFFFFFFF) = 1 (0x00000000_00000001)
        // Upper 32 bits should be 0.
        send_uart("H", 32'hFFFFFFFF, 32'hFFFFFFFF);
        #150;
        $display("MULH (Signed) -1 * -1 = %0d (Expect 0)", dut.ComputeResult);

        $stop;
    end

endmodule

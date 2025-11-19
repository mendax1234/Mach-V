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
        //display is buggy, look at waveform for results
        /*
        // SB offset=2, data=0xEF -> writes to position 2
        send_uart("5", 32'd2, 32'h000000EF);
        #150;
 
        // LB offset=9: loads 0xCC (negative) -> 0xFFFFFFCC
        send_uart("1", 32'd9, 32'd0);
        #150; 
        
        // LBU offset=5: loads 0xDE -> 0x000000DE (no sign extension)
        send_uart("2", 32'd5, 32'd0);
        #150;
        
        // LBU offset=9: loads 0xCC -> 0x000000CC
        send_uart("2", 32'd9, 32'd0);
        #150;
        // LBU offset=14: loads 0xFF -> 0x000000FF
        send_uart("2", 32'd14, 32'd0);
        #150;

    
//         ---- test divide 14 / 2 ----
        send_uart("d", 32'd14, 32'd2);
        #150;
        $display("DIV 14/2 = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);
        
        
       */
        // ---- test subtract 9 - 5 ----
        send_uart("s", 32'd9, 32'd5);
        #150;
        $display("SUB 9-5 = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);
        /*
        send_uart("m", 32'd6, 32'd7);
        #150;
        $display("MUL 6*7 = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);
        
        send_uart("a", 32'd8, 32'd3);
        #150;
        $display("ADD 8+3 = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);
        
        // ---- test xor 10(1010) XOR 5(0101) ----
        send_uart("x", 32'd10, 32'd5);
        #150;
        $display("XOR 1010^0101 = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);
        
        // ---- test add slt(signed) 5<-10?   ----
        send_uart("l",32'hfffffff6,32'h5);
        #150;
        $display("SLT -10<5? = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);
        
        send_uart("M", 32'd15, 32'd4);
        #150;
        $display("REMU 6*7 = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);
        
        // ---- test add slt(signed) 5<-10?   ----
        send_uart("l",32'h5, 32'hfffffff6);
        #150;
        $display("SLT 5<-10? = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);
        
        // ---- test sltu 2<6 ----
        send_uart("u", 32'd2, 32'd6);
        #150;
        $display("SLTU 2<6 = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);
             
        // ---- test sltu 6<2 ----
        send_uart("u", 32'd6, 32'd2);
        #150;
        $display("SLTU 6<2 = %0d (0x%h)", dut.ComputeResult, dut.ComputeResult);
        */
        //#1000;
        $stop;
    end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/11/2023 01:29:27 PM
// Design Name: 
// Module Name: tb_ACLK_XCVR
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


module tb_ACLK_XCVR(

    );
    
reg  RESETn;
reg  CLK_25MHZ;
reg  CLK_156MHZ;
wire UART_TX;
reg  UART_RX;
wire LED_UF1;
wire LED_UF2;
wire XCVR_RXDn;
wire XCVR_RXDp;
wire XCVR_TXDn;
wire XCVR_TXDp;

reg ERROR_INPUTn;

ACLK_XCVR uut(
    .RESETn(RESETn),
    .CLK_25MHZ(CLK_25MHZ),
    .CLK_156MHZ_IN_p(CLK_156MHZ),
    .CLK_156MHZ_IN_n(!CLK_156MHZ),
    .UART_TX(UART_TX),
    .UART_RX(UART_RX),
    .LED_UF1(LED_UF1),
    .LED_UF2(LED_UF2),
    .XCVR_RXDn(XCVR_RXDn),
    .XCVR_RXDp(XCVR_RXDp),
    .XCVR_TXDn(XCVR_TXDn),
    .XCVR_TXDp(XCVR_TXDp),
    .ERROR_INPUTn(ERROR_INPUTn)
    );

    /*
     * Generate a 25Mhz (40ns) clock 
     */
    always begin
        CLK_25MHZ = 1; #20;
        CLK_25MHZ = 0; #20;
    end
    
    /*
     * Generate a 156.39077Mhz (6.394ns) clock 
     */
    always begin
        CLK_156MHZ = 1; #3.197;
        CLK_156MHZ = 0; #3.197;
    end
    
    /*
     * reset_n signal behavior  
     */
    initial begin
        RESETn = 0; #100;
        RESETn = 1;
    end

assign XCVR_RXDn = XCVR_TXDn;
assign XCVR_RXDp = XCVR_TXDp;
    
    initial begin
        force XCVR_RXDn = 0; 
        force XCVR_RXDp = 1; 
        #40000;
        release XCVR_RXDn;
        release XCVR_RXDp;
    end

    initial begin
        ERROR_INPUTn = 1; #150000;
        ERROR_INPUTn = 0; #1000;
        ERROR_INPUTn = 1;
    end

endmodule

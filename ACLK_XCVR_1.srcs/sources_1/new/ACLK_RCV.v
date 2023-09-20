`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/06/2023 11:58:22 AM
// Design Name: 
// Module Name: ACLK_RCV
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


module ACLK_RCV(
    RESETn,
    CLK_81R25MHZ,
    CLK_80MHZ,
    DATA_FROM_XCVR,
    RX_BITSLIP,
    ACLK_EVENT,
    ACLK_DATA,
    ACLK_VALID,
    RX_ALIGNED_OUT

    );
    
    input wire RESETn;
    input wire CLK_81R25MHZ;
    input wire CLK_80MHZ;
    input wire [15:0] DATA_FROM_XCVR;
    output wire RX_BITSLIP;
    output wire [15:0] ACLK_EVENT;
    output wire [31:0] ACLK_DATA;
    output wire ACLK_VALID;
    output wire RX_ALIGNED_OUT;
    
    wire [7:0] ACLK_DATA_TO_RX_GEARBOX;
    
    wire ACLK_DATA_VALID_TO_RX_CHECK;
    wire [55:0] input_to_rx_crc_checker;
    wire [7:0] ACLK_RX_CRC;
    wire ACLK_RX_CRC_VALID;
    reg RX_CRC_EQ_ZERO;  
    
    reg [3:0] rx_pickup_ctr;
    reg [3:0] rx_dropout_ctr;
    reg rx_aligned;
    
    wire [3:0] rx_byteslip_ctr;
    wire [64:0] data65_from_rx_gearbox;
    wire data65_valid_from_rx_gearbox;
    wire RX_BYTESLIP;

// Modified Manchester Decoder
//  16-bit IN from Transceiver
//   8-bit OUT to logic    
    MOD_MANCH_DEC08 uMANCH_DECODER(
        .RESETn(RESETn),
        .CLK(CLK_81R25MHZ), 
        .DATA_IN(DATA_FROM_XCVR),
        .DATA_OUT(ACLK_DATA_TO_RX_GEARBOX));

// Gearbox data accumulator and aligner
// 8-bit data IN from Manchester Decoder
// 65 bits out:
// 64:63 00 - Two start bits
// 62:47 ACLK Event
// 46:15 ACLK Data
// 14:07 8-bit CRC
// 06    Parity Bit (Restores Phase)
// 05:00 Pad Bits
//
// Byteslip input aids in alignment      
    GEARBOX_08_TO_65 uRX_GEARBOX(
          .RESETn(RESETn),
          .CLK_08BIT(CLK_81R25MHZ), 
          .DATA08(ACLK_DATA_TO_RX_GEARBOX),
          .CLK_65BIT(CLK_80MHZ), 
          .DATA65(data65_from_rx_gearbox),
          .DATA65_VALID(data65_valid_from_rx_gearbox),
          .BYTESLIP(RX_BYTESLIP),
          .BYTESLIP_COUNT(rx_byteslip_ctr));
     
    assign ACLK_DATA_VALID_TO_RX_CHECK = data65_valid_from_rx_gearbox;
    assign input_to_rx_crc_checker = data65_from_rx_gearbox[62:7];

// CRC Calculator
//  Performs 8-bit CRC check on 56 bits (Event, Data, CRC-In)
//  If we are aligned, this CRC will calculate to 0x00       
    CRC8_CALC uCRC8_CALC_RX(
          .RESETn    (RESETn),
          .CLK       (CLK_80MHZ), 
          .CALC      (ACLK_DATA_VALID_TO_RX_CHECK),
          .DATA      (input_to_rx_crc_checker),
          .CRC       (ACLK_RX_CRC),
          .CRC_VALID (ACLK_RX_CRC_VALID));
      
    always @(ACLK_RX_CRC) begin
        if (ACLK_RX_CRC == 8'h00)
          RX_CRC_EQ_ZERO <= 1'b1;
        else
          RX_CRC_EQ_ZERO <= 1'b0;
    end
    
// Wait 4 cycles with CRC == 0x00 to declare alignment pickup
// Wait 4 cycles with CRC != 0x00 to declare alignment dropout
    always @(negedge RESETn or posedge CLK_80MHZ) begin
        if (RESETn == 1'b0) begin
          rx_pickup_ctr  <= 4'h0;
          rx_dropout_ctr <= 4'h0;
          rx_aligned     <= 1'b0;
        end
        else if (ACLK_RX_CRC_VALID == 1'b1) begin
          
            if (RX_CRC_EQ_ZERO == 1'b1) begin
              rx_dropout_ctr <= 4'h0;
              
              if (rx_pickup_ctr == 4'h4) begin
                rx_aligned <= 1'b1;
                rx_pickup_ctr <= rx_pickup_ctr;
              end
              else begin
                rx_aligned <= rx_aligned;
                rx_pickup_ctr <= rx_pickup_ctr+1;
              end
            
            end  
            else begin
              rx_pickup_ctr <= 4'h0;
              
              if (rx_dropout_ctr == 4'h4) begin
                rx_aligned <= 1'b0;
                rx_dropout_ctr <= rx_dropout_ctr;
              end
              else begin
                rx_aligned <= rx_aligned;
                rx_dropout_ctr <= rx_dropout_ctr+1;
              end
            end
        end
        else begin
            rx_pickup_ctr  <= rx_pickup_ctr;
            rx_dropout_ctr <= rx_dropout_ctr;
            rx_aligned     <= rx_aligned;
        end
    end
    
    assign ACLK_EVENT = data65_from_rx_gearbox[62:47];
    assign ACLK_DATA = data65_from_rx_gearbox[46:15];
    assign ACLK_VALID = data65_valid_from_rx_gearbox & RX_CRC_EQ_ZERO & rx_aligned;
    assign RX_ALIGNED_OUT = rx_aligned;

// Bitslip controller watches for alignment
// Tells transceiver to slip one bit at a time as required
// Tells gearbox to slip one byte at a time as required.      
    BITSLIP_CTRL uRX_BITSLIP_CTRL(
      .RESETn     (RESETn),
      .CLK65      (CLK_80MHZ),
      .ALIGNED_IN (rx_aligned),
      .VALID_IN   (ACLK_RX_CRC_VALID),
      .BITSLIP    (RX_BITSLIP), 
      .BYTESLIP   (RX_BYTESLIP));
      
endmodule

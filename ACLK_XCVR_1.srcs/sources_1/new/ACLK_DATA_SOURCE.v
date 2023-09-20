`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/11/2023 12:00:03 PM
// Design Name: 
// Module Name: ACLK_DATA_SOURCE
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


module ACLK_DATA_SOURCE(
    RESETn,
    CLK_81R25MHZ,
    CLK_80MHZ,
    ACLK_TX_TO_XCVR,
    ERROR_INPUTn
    );
    
input wire RESETn;
input wire CLK_81R25MHZ;
input wire CLK_80MHZ;
output wire [15:0] ACLK_TX_TO_XCVR;
input wire ERROR_INPUTn;

reg [3:0] lfsr_adv_ctr;
reg lfsr_adv0, lfsr_adv1;
wire [47:0] prpg_tx_output, prpg_tx_biterrs, PR_PATT_48;
wire [7:0] ACLK_TX_CRC;
wire ACLK_TX_CRC_VALID;
wire [129:0] ACLK_TX_TO_GEARBOX;
wire ACLK_TX_TO_GEARBOX_VALID;
wire [15:0] ACLK_DATA_OUT, ACLK_DATA_OUT_bitreverse;

always @(negedge RESETn or posedge CLK_80MHZ) begin
  if(!RESETn) begin
    lfsr_adv_ctr <= 4'h0;
  end
  else begin
    if (lfsr_adv_ctr == 4'h7) begin
        lfsr_adv_ctr <= 4'h0;
    end
    else begin
        lfsr_adv_ctr <= lfsr_adv_ctr+1;
    end
  end
end

always @(negedge RESETn or posedge CLK_80MHZ) begin
  if(!RESETn) begin
      lfsr_adv0 <= 0;
      lfsr_adv1 <= 0;
  end
  else begin
    if (lfsr_adv_ctr == 4'h5) begin
        lfsr_adv0 <= 1;
        lfsr_adv1 <= 0;
    end
    else if (lfsr_adv_ctr == 4'h6) begin
        lfsr_adv0 <= 0;
        lfsr_adv1 <= 1;
    end
    else begin
        lfsr_adv0 <= 0;
        lfsr_adv1 <= 0;
    end
  end
end

LFSR48 uPATTERN_GEN(
    .CLK(CLK_80MHZ),
    .RESETn(RESETn),
    .ADV(lfsr_adv0),
    .LOAD(1'b0),
    .D(48'h000000000000),
    .Q(prpg_tx_output)
//    .Q()
    );

  assign prpg_tx_biterrs = {28'h0000000, !ERROR_INPUTn, 3'b000, 16'h0000};
  assign PR_PATT_48 = prpg_tx_output ^ prpg_tx_biterrs;

//  assign prpg_tx_output = 48'hFF00F0C3AA55;
//  assign prpg_tx_output = 48'h000000000000;

CRC8_CALC uCRC8_CALC_TX(
    .RESETn (RESETn),
    .CLK (CLK_80MHZ), 
    .CALC (lfsr_adv1),
    .DATA ({PR_PATT_48, 8'h00}),
    .CRC(ACLK_TX_CRC),
    .CRC_VALID(ACLK_TX_CRC_VALID)
    );
  
MOD_MANCH_ENC65 uMANCH_ENCODER(
    .RESETn (RESETn),
    .CLK (CLK_80MHZ), 
    .ENCODE (ACLK_TX_CRC_VALID),
    .DATA48_IN (PR_PATT_48),
    .CRC_IN (ACLK_TX_CRC),
    .DATA_OUT (ACLK_TX_TO_GEARBOX),
    .DATA_OUT_VALID (ACLK_TX_TO_GEARBOX_VALID)
    );
  
GEARBOX_130_TO_16 uTX_GEARBOX(
    .RESETn        (RESETn),
    .CLK_130BIT    (CLK_80MHZ), 
    .DATA_IN       (ACLK_TX_TO_GEARBOX),
    .VALID_IN      (ACLK_TX_TO_GEARBOX_VALID),
    .CLK_16BIT     (CLK_81R25MHZ), 
    .DATA_OUT      (ACLK_DATA_OUT)
    );
      
generate 
    for (genvar n=0 ; n < 16 ; n=n+1 ) begin 
        assign ACLK_DATA_OUT_bitreverse[n] = ACLK_DATA_OUT[15-n];
    end 
endgenerate 

//assign ACLK_TX_TO_XCVR = ACLK_DATA_OUT;
assign ACLK_TX_TO_XCVR = ACLK_DATA_OUT_bitreverse;

endmodule

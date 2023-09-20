`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/29/2023 12:33:32 PM
// Design Name: 
// Module Name: ACLK_XCVR
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


module ACLK_XCVR(
    RESETn,
    CLK_25MHZ,
//    CLK_156MHZ,
    CLK_156MHZ_IN_p,
    CLK_156MHZ_IN_n,
    UART_TX,
    UART_RX,
    LED_UF1,
    LED_UF2,
    XCVR_RXDn,
    XCVR_RXDp,
    XCVR_TXDn,
    XCVR_TXDp,
    ERROR_INPUTn,
    PMOD2_1,
    PMOD2_3,
    PMOD2_5,
    PMOD2_7,
    PMOD3_1,
    PMOD3_3,
    PMOD3_5,
    PMOD3_7,
    SFP_TXDIS
    );
    
    input  wire RESETn;
    input  wire CLK_25MHZ;
    input  wire CLK_156MHZ_IN_p; // 156.39 MHz = 1300 / 8.3125
    input  wire CLK_156MHZ_IN_n;
    //input  wire CLK_156MHZ; // 156.39 MHz = 1300 / 8.3125
    output wire UART_TX;
    input  wire UART_RX;
    output wire LED_UF1;
    output wire LED_UF2;
    input  wire XCVR_RXDn;
    input  wire XCVR_RXDp;
    output wire XCVR_TXDn;
    output wire XCVR_TXDp;
    input  wire ERROR_INPUTn;
    output wire PMOD2_1;
    output wire PMOD2_3;
    output wire PMOD2_5;
    output wire PMOD2_7;
    output wire PMOD3_1;
    output wire PMOD3_3;
    output wire PMOD3_5;
    output wire PMOD3_7;
    output wire SFP_TXDIS;
    
    wire rtl_reset;
    wire CLK_156MHZ;
    
    wire CLK_81R25MHZ_tx,          CLK_81R25MHZ_rx;
    wire CLK_81R25MHZ_tx_buffered, CLK_81R25MHZ_rx_buffered;
    wire CLK_80MHZ_tx, CLK_80MHZ_rx;
    wire [15:0] ACLK_TX_TO_XCVR;
    wire [15:0] ACLK_RX_FROM_XCVR;
    wire [15:0] ACLK_RX_FROM_XCVR_bitreverse;
    reg [15:0] ACLK_RX_FROM_XCVR_reg;
    
    wire XCVR_qpll0outclk_out;
    wire XCVR_qpll0outrefclk_out;
    wire XCVR_gtpowergood_out;
    wire XCVR_rxpmaresetdone_out;
    wire XCVR_txpmaresetdone_out;
    
    wire RX_BITSLIP;
    reg RX_BITSLIP_reg;

    wire [15:0] aclk_event;
    wire [31:0] aclk_data;
    wire aclk_valid;
    wire rx_aligned;
  
    wire reset_rx_cdr_stable;
    wire reset_tx_done;
    wire reset_rx_done;
    
    reg [31:0] rx_bitslip_ctr;
    
    reg  [7:0] crnt_st_patt_chk;
    reg [7:0] next_st_patt_chk;
    reg  prpg_rx_load;
    wire [47:0] prpg_rx_d, prpg_rx_q;
    reg  patt_chk_sm_adv;
    reg  rx_patt_match;

    reg [31:0] rx_patt_err_cnt, rx_patt_err_cnt_rdreg;
    reg rx_patt_err_cnt_clr, rx_patt_err_cnt_inc;
  
    reg io_read_cap, io_read_smpl;
    wire io_read_stb;

    wire io_read, io_chipselect;
    wire[11:0] io_address;
    reg [31:0] io_readdata;
    
    reg [31:0] hb_ctr;
  
    reg [7:0] tx_coreclock_ctr, rx_coreclock_ctr;
    reg tx_coreclock_strobe, rx_coreclock_strobe;
  
    assign rtl_reset = !RESETn;
    
    ACLK_DATA_SOURCE uACLK_DATA_SOURCE(
        .RESETn(RESETn),
        .CLK_81R25MHZ(CLK_81R25MHZ_tx_buffered),
        .CLK_80MHZ(CLK_80MHZ_tx),
        .ACLK_TX_TO_XCVR(ACLK_TX_TO_XCVR),
        .ERROR_INPUTn(ERROR_INPUTn)
        );
    
    gtwizard_ultrascale_0 uGT_XCVR(
        .gtwiz_userclk_tx_active_in(1'b1),
        .gtwiz_userclk_rx_active_in(1'b1),
        .gtwiz_reset_clk_freerun_in(CLK_25MHZ),
        .gtwiz_reset_all_in(rtl_reset),
        .gtwiz_reset_tx_pll_and_datapath_in(rtl_reset),
        .gtwiz_reset_tx_datapath_in(rtl_reset),
        .gtwiz_reset_rx_pll_and_datapath_in(rtl_reset),
        .gtwiz_reset_rx_datapath_in(rtl_reset),
        .gtwiz_reset_rx_cdr_stable_out(reset_rx_cdr_stable),
        .gtwiz_reset_tx_done_out(reset_tx_done),
        .gtwiz_reset_rx_done_out(reset_rx_done),
        .gtwiz_userdata_tx_in(ACLK_TX_TO_XCVR),
        .gtwiz_userdata_rx_out(ACLK_RX_FROM_XCVR_bitreverse),
        .gtrefclk00_in(CLK_156MHZ),
//        .qpll0refclksel_in(3'b001),
        .qpll0outclk_out(XCVR_qpll0outclk_out),
        .qpll0outrefclk_out(XCVR_qpll0outrefclk_out),
        .gthrxn_in(XCVR_RXDn),
        .gthrxp_in(XCVR_RXDp),
//        .rxslide_in(1'b0),
        .rxslide_in(RX_BITSLIP),
        .rxusrclk_in(CLK_81R25MHZ_rx_buffered),
        .rxusrclk2_in(CLK_81R25MHZ_rx_buffered),
        .txusrclk_in(CLK_81R25MHZ_tx_buffered),
        .txusrclk2_in(CLK_81R25MHZ_tx_buffered),
        .gthtxn_out(XCVR_TXDn),
        .gthtxp_out(XCVR_TXDp),
        .gtpowergood_out(XCVR_gtpowergood_out),
        .rxoutclk_out(CLK_81R25MHZ_rx),
        .rxpmaresetdone_out(XCVR_rxpmaresetdone_out),
        .txoutclk_out(CLK_81R25MHZ_tx),
        .txpmaresetdone_out(XCVR_txpmaresetdone_out)
    );
    
//    clk_wiz_0 uCLK_WIZ_156(
//        .clk_out1(CLK_156MHZ),
//        .reset(rtl_reset),
//        .locked(),
//        .clk_in1_p(CLK_156MHZ_IN_p),
//        .clk_in1_n(CLK_156MHZ_IN_n)
//     );
    
    // IBUFDS_GTE4: Gigabit Transceiver Buffer
    //              UltraScale
    // Xilinx HDL Language Template, version 2023.1
    
    IBUFDS_GTE4 #(
       .REFCLK_EN_TX_PATH(1'b0),   // Refer to Transceiver User Guide.
       .REFCLK_HROW_CK_SEL(2'b00), // Refer to Transceiver User Guide.
       .REFCLK_ICNTL_RX(2'b00)     // Refer to Transceiver User Guide.
    )
    IBUFDS_GTE4_inst (
       .O(CLK_156MHZ),         // 1-bit output: Refer to Transceiver User Guide.
       .ODIV2(), // 1-bit output: Refer to Transceiver User Guide.
       .CEB(1'b0),     // 1-bit input: Refer to Transceiver User Guide.
       .I(CLK_156MHZ_IN_p),         // 1-bit input: Refer to Transceiver User Guide.
       .IB(CLK_156MHZ_IN_n)        // 1-bit input: Refer to Transceiver User Guide.
    );

    // End of IBUFDS_GTE4_inst instantiation

    BUFG_GT uBUF_CLK_81R25MHZ_tx (
        .CE      (1'b1),
        .CEMASK  (1'b0),
        .CLR     (rtl_reset),
        .CLRMASK (1'b0),
        .DIV     (3'b000),
        .I       (CLK_81R25MHZ_tx),
        .O       (CLK_81R25MHZ_tx_buffered)
    );
      
    BUFG_GT uBUF_CLK_81R25MHZ_rx (
        .CE      (1'b1),
        .CEMASK  (1'b0),
        .CLR     (rtl_reset),
        .CLRMASK (1'b0),
        .DIV     (3'b000),
        .I       (CLK_81R25MHZ_rx),
        .O       (CLK_81R25MHZ_rx_buffered)
    );
      
    generate 
        for (genvar n=0 ; n < 16 ; n=n+1 ) begin 
            assign ACLK_RX_FROM_XCVR[n] = ACLK_RX_FROM_XCVR_bitreverse[15-n];
        end 
    endgenerate 
    
    always @(negedge RESETn or posedge CLK_81R25MHZ_rx_buffered) begin
//    always @(negedge RESETn or posedge CLK_81R25MHZ_rx) begin
        if (RESETn == 1'b0)
            ACLK_RX_FROM_XCVR_reg <= 16'h0000;
        else
            ACLK_RX_FROM_XCVR_reg <= ACLK_RX_FROM_XCVR;
    end
  
    clk_wiz_81R25_to_80MHz uPLL_TX(
        .reset(rtl_reset),
        .clk_in1(CLK_81R25MHZ_tx_buffered),
        .clk_out1(CLK_80MHZ_tx),
        .locked()
    );
    
    clk_wiz_81R25_to_80MHz uPLL_RX(
        .reset(rtl_reset),
        .clk_in1(CLK_81R25MHZ_rx_buffered),
        .clk_out1(CLK_80MHZ_rx),
        .locked()
    );
    
    PLL_81R25_PLS_45DEG uPLL_RX_81R25_LAG_45DEG(
        .reset(rtl_reset),
        .clk_in1(CLK_81R25MHZ_rx_buffered),
        .clk_out1(CLK_81R25MHZ_RX_LAG_45DEG),
        .locked()
    );
    
    ACLK_RCV uACLK_RCV(
        .RESETn(RESETn),
        .CLK_81R25MHZ(CLK_81R25MHZ_RX_LAG_45DEG),
//        .CLK_81R25MHZ(CLK_81R25MHZ_rx_buffered),
//        .CLK_81R25MHZ(CLK_81R25MHZ_rx),
        .CLK_80MHZ(CLK_80MHZ_rx),
//        .DATA_FROM_XCVR(ACLK_RX_FROM_XCVR),
        .DATA_FROM_XCVR(ACLK_RX_FROM_XCVR_reg),
        .RX_BITSLIP(RX_BITSLIP),
        .ACLK_EVENT(aclk_event),
        .ACLK_DATA(aclk_data),
        .ACLK_VALID(aclk_valid),
        .RX_ALIGNED_OUT(rx_aligned)
    );
    
    always @(negedge RESETn or posedge CLK_80MHZ_rx) begin
        if (RESETn == 1'b0)
          RX_BITSLIP_reg <= 1'b0;
        else
          RX_BITSLIP_reg <= RX_BITSLIP;
    end
  
    always @(negedge RESETn or posedge CLK_80MHZ_rx) begin
        if (RESETn == 1'b0)
          rx_bitslip_ctr <= 32'h00000000;
        else begin
          if ((RX_BITSLIP == 1'b1) && (RX_BITSLIP_reg == 1'b0))
            rx_bitslip_ctr <= rx_bitslip_ctr + 1;
          else
            rx_bitslip_ctr <= rx_bitslip_ctr;
        end
    end
  
  LFSR48 uPRPG_RX(
      .RESETn (RESETn),
      .CLK    (CLK_80MHZ_rx), 
      .ADV    (aclk_valid),
      .LOAD   (prpg_rx_load),
      .D      (prpg_rx_d),
      .Q      (prpg_rx_q));
      
  assign prpg_rx_d = {aclk_event, aclk_data};
  
  always@(negedge RESETn or posedge CLK_80MHZ_rx) begin
    if (RESETn == 1'b0)
      patt_chk_sm_adv <= 1'b0;
    else
      patt_chk_sm_adv <= aclk_valid;
  end
  
  always@(negedge RESETn or posedge CLK_80MHZ_rx) begin
    if (RESETn == 1'b0)
      crnt_st_patt_chk <= 8'h00;
    else begin
      if ((rx_aligned == 1'b0) && (crnt_st_patt_chk != 8'h00))
        crnt_st_patt_chk <= 8'h01;
      else
        crnt_st_patt_chk <= next_st_patt_chk;
    end
  end
  
  always @(crnt_st_patt_chk or rx_aligned or patt_chk_sm_adv or rx_patt_match) begin
    case (crnt_st_patt_chk)
      8'h00 : begin
        rx_patt_err_cnt_clr <= 1'b1;
        rx_patt_err_cnt_inc <= 1'b0;
        prpg_rx_load <= 1'b0;
        next_st_patt_chk <= 8'h01;
      end
      
      8'h01 : begin
        rx_patt_err_cnt_inc <= 1'b0;
        rx_patt_err_cnt_clr <= 1'b0;
        prpg_rx_load <= 1'b0;
        
        if (rx_aligned == 1'b1)
          next_st_patt_chk <= 8'h10;
        else
          next_st_patt_chk <= 8'h01;
      end
      
      8'h10 : begin
        rx_patt_err_cnt_inc <= 1'b0;
        rx_patt_err_cnt_clr <= 1'b0;
        prpg_rx_load <= 1'b1;
        next_st_patt_chk <= 8'h20;
      end
      
      8'h20 : begin
        rx_patt_err_cnt_clr <= 1'b0;
        rx_patt_err_cnt_inc <= 1'b0;
        prpg_rx_load <= 1'b0;
        
        if (patt_chk_sm_adv == 1'b1)
          next_st_patt_chk <= 8'h21;
        else
          next_st_patt_chk <= 8'h20;
      end
      
      8'h21 : begin
        rx_patt_err_cnt_clr <= 1'b0;
        prpg_rx_load <= 1'b0;
        
        if (rx_patt_match == 1'b0) begin
          rx_patt_err_cnt_inc <= 1'b1;
          next_st_patt_chk <= 8'h10;
        end
        else begin
          rx_patt_err_cnt_inc <= 1'b0;
          next_st_patt_chk <= 8'h20;
        end
      end
      
      default : begin
        rx_patt_err_cnt_clr <= 1'b0;
        rx_patt_err_cnt_inc <= 1'b0;
        prpg_rx_load <= 1'b0;
        next_st_patt_chk <= 8'h00;
      end
        
    endcase
  end
  

  always @(negedge RESETn or posedge CLK_80MHZ_rx)
  begin
    if (RESETn == 1'b0)
      rx_patt_match <= 1'b0;
    else if (patt_chk_sm_adv == 1'b1) begin
        if (prpg_rx_d == prpg_rx_q)
          rx_patt_match <= 1'b1;
        else
          rx_patt_match <= 1'b0;
    end
    else
        rx_patt_match <= rx_patt_match;
  end
  
  always @(negedge RESETn or posedge CLK_80MHZ_rx)
  begin
    if (RESETn == 1'b0)
      rx_patt_err_cnt <= 32'h00000000;
    else begin
      if (rx_patt_err_cnt_clr == 1'b1)
        rx_patt_err_cnt <= 32'h00000000;
      else if (rx_patt_err_cnt_inc == 1'b1)
        rx_patt_err_cnt <= rx_patt_err_cnt + 1;
      else
        rx_patt_err_cnt <= rx_patt_err_cnt;
    end
  end

  assign io_read = 1'b0;
  assign io_chipselect = 1'b0;
  assign io_address = 12'h000;
  
  always @(negedge RESETn or posedge CLK_80MHZ_rx)
  begin
    if (RESETn == 1'b0) begin
      io_read_cap <= 1'b0;
      io_read_smpl <= 1'b0;
    end
    else begin
      io_read_cap <= io_read;
      io_read_cap <= 1'b0;
      io_read_smpl <= io_read_cap;
    end
  end
  
  assign io_read_stb = io_read_cap & !io_read_smpl;
  
  always @(negedge RESETn or posedge CLK_80MHZ_rx)
  begin
    if (RESETn == 1'b0)
      rx_patt_err_cnt_rdreg <= 32'h00000000;
    else begin
      if ((io_chipselect == 1'b1) && (io_address == 12'h000) && (io_read_stb == 1'b1))
        rx_patt_err_cnt_rdreg <= rx_patt_err_cnt;
      else
        rx_patt_err_cnt_rdreg <= rx_patt_err_cnt_rdreg;
    end
  end
  
  always @(io_address, rx_patt_err_cnt_rdreg) begin
    case (io_address)
      12'h000 :
        io_readdata <= rx_patt_err_cnt_rdreg;
        
      default :
        io_readdata <= 32'h00000000;
    endcase
  end
  
  assign LED_UF2 = rx_aligned;
  
  assign PMOD2_1 = tx_coreclock_strobe;
  assign PMOD2_3 = rx_coreclock_strobe;
  assign PMOD2_5 = RX_BITSLIP;
  assign PMOD2_7 = prpg_rx_load;

  assign PMOD3_1 = aclk_valid;

  always @(negedge RESETn or posedge CLK_25MHZ)
  begin
    if (RESETn == 1'b0)
      hb_ctr <= 32'h00000000;
    else
      hb_ctr <= hb_ctr + 1;
  end
  
  assign LED_UF1 = hb_ctr[24];
  
  assign SFP_TXDIS = 1'b0;
  
//------------------------------------------------------------  
//------------------------------------------------------------  
  always @(negedge RESETn or posedge CLK_81R25MHZ_tx_buffered)
  begin
    if (RESETn == 1'b0)
        tx_coreclock_ctr <= 8'h00;
    else begin
        if (tx_coreclock_ctr == 8'h5F)
            tx_coreclock_ctr <= 8'h00;
        else
            tx_coreclock_ctr <= tx_coreclock_ctr + 1;
    end
  end
  
  always @(negedge RESETn or posedge CLK_81R25MHZ_tx_buffered)
  begin
    if (RESETn == 1'b0)
        tx_coreclock_strobe <= 1'b0;
    else begin
        if ((tx_coreclock_ctr == 8'h00) || (tx_coreclock_ctr == 8'h02) || (tx_coreclock_ctr == 8'h04) || (tx_coreclock_ctr == 8'h06))
            tx_coreclock_strobe <= 1'b1;
        else
            tx_coreclock_strobe <= 1'b0;
    end
  end
  
//------------------------------------------------------------  
//------------------------------------------------------------  
  always @(negedge RESETn or posedge CLK_81R25MHZ_rx_buffered)
  begin
    if (RESETn == 1'b0)
        rx_coreclock_ctr <= 8'h00;
    else begin
        if (rx_coreclock_ctr == 8'h5F)
            rx_coreclock_ctr <= 8'h00;
        else
            rx_coreclock_ctr <= rx_coreclock_ctr + 1;
    end
  end
  
  always @(negedge RESETn or posedge CLK_81R25MHZ_rx_buffered)
  begin
    if (RESETn == 1'b0)
        rx_coreclock_strobe <= 1'b0;
    else begin
        if ((rx_coreclock_ctr == 8'h00) || (rx_coreclock_ctr == 8'h02) || (rx_coreclock_ctr == 8'h04))
            rx_coreclock_strobe <= 1'b1;
        else
            rx_coreclock_strobe <= 1'b0;
    end
  end
  
  
  

endmodule

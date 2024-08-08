//------------------------------------------------------------------------
// memif_xem6006.v
//
// Memory interface for the XEM6006.
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2009 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------
`timescale 1ns/1ps
// Don't use this because the Xilinx MIG generates code that doesn't declare
// net types on module inputs, so it's not compliant.
//`default_nettype none

module mem_if  #(
	parameter C3_P0_MASK_SIZE           = 8,
	parameter C3_P0_DATA_PORT_SIZE      = 64,
	parameter C3_P1_MASK_SIZE           = 8,
	parameter C3_P1_DATA_PORT_SIZE      = 64,
	parameter DEBUG_EN                = 0,       
	                                    // # = 1, Enable debug signals/controls,
	                                    //   = 0, Disable debug signals/controls.
	parameter C3_MEMCLK_PERIOD        = 3200,       
	                                    // Memory data transfer clock period
	parameter C3_CALIB_SOFT_IP        = "TRUE",       
	                                    // # = TRUE, Enables the soft calibration logic,
	                                    // # = FALSE, Disables the soft calibration logic.
	parameter C3_SIMULATION           = "FALSE",       
	                                    // # = TRUE, Simulating the design. Useful to reduce the simulation time,
	                                    // # = FALSE, Implementing the design.
	parameter C3_HW_TESTING           = "FALSE",       
	                                    // Determines the address space accessed by the traffic generator,
	                                    // # = FALSE, Smaller address space,
	                                    // # = TRUE, Large address space.
	parameter C3_RST_ACT_LOW          = 0,       
	                                    // # = 1 for active low reset,
	                                    // # = 0 for active high reset.
	parameter C3_INPUT_CLK_TYPE       = "SINGLE_ENDED",       
	                                    // input clock type DIFFERENTIAL or SINGLE_ENDED
	parameter C3_MEM_ADDR_ORDER       = "ROW_BANK_COLUMN",       
	                                    // The order in which user address is provided to the memory controller,
	                                    // ROW_BANK_COLUMN or BANK_ROW_COLUMN
	parameter C3_NUM_DQ_PINS          = 16,       
	                                    // External memory data width
	parameter C3_MEM_ADDR_WIDTH       = 13,       
	                                    // External memory address width
	parameter C3_MEM_BANKADDR_WIDTH   = 3        
	                                    // External memory bank address width      
	)
	(
	// Clocks
	input  wire                                async_rst,
	input  wire                                sysclk_2x,
	input  wire                                sysclk_2x_180,
	input  wire                                pll_ce_0,
	input  wire                                pll_ce_90,
	input  wire                                pll_lock,
	input  wire                                mcb_drp_clk,
	output wire                                calib_done,

	// Interfaces
	input  wire                                p0_cmd_clk,
	input  wire                                p0_cmd_en,
	input  wire [2:0]                          p0_cmd_instr,
	input  wire [5:0]                          p0_cmd_bl,
	input  wire [29:0]                         p0_cmd_byte_addr,
	input  wire                                p0_wr_clk,
	input  wire                                p0_wr_en,
	input  wire [63:0]                         p0_wr_data,
	input  wire [7:0]                          p0_wr_mask,
	
	input  wire                                p1_cmd_clk,
	input  wire                                p1_cmd_en,
	input  wire [2:0]                          p1_cmd_instr,
	input  wire [5:0]                          p1_cmd_bl,
	input  wire [29:0]                         p1_cmd_byte_addr,
	input  wire                                p1_rd_clk,
	input  wire                                p1_rd_en,
	output wire [63:0]                         p1_rd_data,
	output wire                                p1_rd_empty,
	
	// DDR Memory
	inout  wire [C3_NUM_DQ_PINS-1:0]           ddr2_dq,
	output wire [C3_MEM_ADDR_WIDTH-1:0]        ddr2_a,
	output wire [C3_MEM_BANKADDR_WIDTH-1:0]    ddr2_ba,
	output wire                                ddr2_ras_n,
	output wire                                ddr2_cas_n,
	output wire                                ddr2_we_n,
	output wire                                ddr2_odt,
	output wire                                ddr2_cke,
	output wire                                ddr2_dm,
	inout  wire                                ddr2_udqs,
	inout  wire                                ddr2_udqs_n,
	inout  wire                                ddr2_rzq,
	inout  wire                                ddr2_zio,
	output wire                                ddr2_udm,
	inout  wire                                ddr2_dqs,
	inout  wire                                ddr2_dqs_n,
	output wire                                ddr2_ck,
	output wire                                ddr2_ck_n,
	output wire                                ddr2_cs_n
	);


// The parameter CX_PORT_ENABLE shows all the active user ports in the design.
// For example, the value 6'b111100 tells that only port-2, port-3, port-4
// and port-5 are enabled. The other two ports are inactive. An inactive port
// can be a disabled port or an invisible logical port. Few examples to the 
// invisible logical port are port-4 and port-5 in the user port configuration,
// Config-2: Four 32-bit bi-directional ports and the ports port-2 through
// port-5 in Config-4: Two 64-bit bi-directional ports. Please look into the 
// Chapter-2 of ug388.pdf in the /docs directory for further details.
   localparam C3_PORT_ENABLE              = 6'b000011;
   localparam C3_PORT_CONFIG             =  "B64_B64";
   localparam C3_P0_PORT_MODE             =  "BI_MODE";
   localparam C3_P1_PORT_MODE             =  "BI_MODE";
   localparam C3_P2_PORT_MODE             =  "NONE";
   localparam C3_P3_PORT_MODE             =  "NONE";
   localparam C3_P4_PORT_MODE             =  "NONE";
   localparam C3_P5_PORT_MODE             =  "NONE";    
   localparam C3_ARB_ALGORITHM        = 0;       
   localparam C3_ARB_NUM_TIME_SLOTS   = 12;       
   localparam C3_ARB_TIME_SLOT_0      = 6'o01;       
   localparam C3_ARB_TIME_SLOT_1      = 6'o10;       
   localparam C3_ARB_TIME_SLOT_2      = 6'o01;       
   localparam C3_ARB_TIME_SLOT_3      = 6'o10;       
   localparam C3_ARB_TIME_SLOT_4      = 6'o01;       
   localparam C3_ARB_TIME_SLOT_5      = 6'o10;       
   localparam C3_ARB_TIME_SLOT_6      = 6'o01;       
   localparam C3_ARB_TIME_SLOT_7      = 6'o10;       
   localparam C3_ARB_TIME_SLOT_8      = 6'o01;       
   localparam C3_ARB_TIME_SLOT_9      = 6'o10;       
   localparam C3_ARB_TIME_SLOT_10     = 6'o01;       
   localparam C3_ARB_TIME_SLOT_11     = 6'o10;       
   localparam C3_MEM_TRAS             = 40000;       
   localparam C3_MEM_TRCD             = 15000;       
   localparam C3_MEM_TREFI            = 7800000;       
   localparam C3_MEM_TRFC             = 127500;       
   localparam C3_MEM_TRP              = 15000;       
   localparam C3_MEM_TWR              = 15000;       
   localparam C3_MEM_TRTP             = 7500;       
   localparam C3_MEM_TWTR             = 7500;       
   localparam C3_MEM_TYPE             = "DDR2";       
   localparam C3_MEM_DENSITY          = "1Gb";       
   localparam C3_MEM_BURST_LEN        = 4;       
   localparam C3_MEM_CAS_LATENCY      = 5;       
   localparam C3_MEM_NUM_COL_BITS     = 10;       
   localparam C3_MEM_DDR1_2_ODS       = "REDUCED";       
   localparam C3_MEM_DDR2_RTT         = "50OHMS";       
   localparam C3_MEM_DDR2_DIFF_DQS_EN  = "YES";       
   localparam C3_MEM_DDR2_3_PA_SR     = "FULL";       
   localparam C3_MEM_DDR2_3_HIGH_TEMP_SR  = "NORMAL";       
   localparam C3_MEM_DDR3_CAS_LATENCY  = 6;       
   localparam C3_MEM_DDR3_ODS         = "DIV6";       
   localparam C3_MEM_DDR3_RTT         = "DIV2";       
   localparam C3_MEM_DDR3_CAS_WR_LATENCY  = 5;       
   localparam C3_MEM_DDR3_AUTO_SR     = "ENABLED";       
   localparam C3_MEM_MOBILE_PA_SR     = "FULL";       
   localparam C3_MEM_MDDR_ODS         = "FULL";       
   localparam C3_MC_CALIB_BYPASS      = "NO";       
   localparam C3_MC_CALIBRATION_MODE  = "CALIBRATION";       
   localparam C3_MC_CALIBRATION_DELAY  = "HALF";       
   localparam C3_SKIP_IN_TERM_CAL     = 0;       
   localparam C3_SKIP_DYNAMIC_CAL     = 0;       
   localparam C3_LDQSP_TAP_DELAY_VAL  = 0;       
   localparam C3_LDQSN_TAP_DELAY_VAL  = 0;       
   localparam C3_UDQSP_TAP_DELAY_VAL  = 0;       
   localparam C3_UDQSN_TAP_DELAY_VAL  = 0;       
   localparam C3_DQ0_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ1_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ2_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ3_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ4_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ5_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ6_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ7_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ8_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ9_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ10_TAP_DELAY_VAL   = 0;       
   localparam C3_DQ11_TAP_DELAY_VAL   = 0;       
   localparam C3_DQ12_TAP_DELAY_VAL   = 0;       
   localparam C3_DQ13_TAP_DELAY_VAL   = 0;       
   localparam C3_DQ14_TAP_DELAY_VAL   = 0;       
   localparam C3_DQ15_TAP_DELAY_VAL   = 0;       
   localparam C3_MCB_USE_EXTERNAL_BUFPLL  = 1;       
   localparam C3_SMALL_DEVICE         = "FALSE";       
   localparam C3_p0_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000200;
   localparam C3_p0_DATA_MODE                       = 4'b0010;
   localparam C3_p0_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h02ffffff:32'h000003ff;
   localparam C3_p0_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hfc000000:32'hfffff800;
   localparam C3_p0_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000200;
   localparam C3_p1_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h03000000:32'h00000400;
   localparam C3_p1_DATA_MODE                       = 4'b0010;
   localparam C3_p1_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h04ffffff:32'h000005ff;
   localparam C3_p1_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff000;
   localparam C3_p1_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h03000000:32'h00000400;
   localparam C3_p2_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000600;
   localparam C3_p2_DATA_MODE                       = 4'b0010;
   localparam C3_p2_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h06ffffff:32'h000007ff;
   localparam C3_p2_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff000;
   localparam C3_p2_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000600;
   localparam C3_p3_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000700;
   localparam C3_p3_DATA_MODE                       = 4'b0010;
   localparam C3_p3_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h02ffffff:32'h000008ff;
   localparam C3_p3_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hfc000000:32'hfffff000;
   localparam C3_p3_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000700;
   localparam C3_p4_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;
   localparam C3_p4_DATA_MODE                       = 4'b0010;
   localparam C3_p4_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h06ffffff:32'h000006ff;
   localparam C3_p4_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff800;
   localparam C3_p4_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;
   localparam C3_p5_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;
   localparam C3_p5_DATA_MODE                       = 4'b0010;
   localparam C3_p5_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h06ffffff:32'h000006ff;
   localparam C3_p5_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff800;
   localparam C3_p5_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;
   localparam DBG_WR_STS_WIDTH        = 32;
   localparam DBG_RD_STS_WIDTH        = 32;
   localparam C3_ARB_TIME0_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_0[5:3], C3_ARB_TIME_SLOT_0[2:0]};
   localparam C3_ARB_TIME1_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_1[5:3], C3_ARB_TIME_SLOT_1[2:0]};
   localparam C3_ARB_TIME2_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_2[5:3], C3_ARB_TIME_SLOT_2[2:0]};
   localparam C3_ARB_TIME3_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_3[5:3], C3_ARB_TIME_SLOT_3[2:0]};
   localparam C3_ARB_TIME4_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_4[5:3], C3_ARB_TIME_SLOT_4[2:0]};
   localparam C3_ARB_TIME5_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_5[5:3], C3_ARB_TIME_SLOT_5[2:0]};
   localparam C3_ARB_TIME6_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_6[5:3], C3_ARB_TIME_SLOT_6[2:0]};
   localparam C3_ARB_TIME7_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_7[5:3], C3_ARB_TIME_SLOT_7[2:0]};
   localparam C3_ARB_TIME8_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_8[5:3], C3_ARB_TIME_SLOT_8[2:0]};
   localparam C3_ARB_TIME9_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_9[5:3], C3_ARB_TIME_SLOT_9[2:0]};
   localparam C3_ARB_TIME10_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_10[5:3], C3_ARB_TIME_SLOT_10[2:0]};
   localparam C3_ARB_TIME11_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C3_ARB_TIME_SLOT_11[5:3], C3_ARB_TIME_SLOT_11[2:0]};
   
  wire                              c3_error;
  wire                              c3_clk0;

wire				c3_p0_cmd_clk;
wire				c3_p0_cmd_en;
wire[2:0]			c3_p0_cmd_instr;
wire[5:0]			c3_p0_cmd_bl;
wire[29:0]			c3_p0_cmd_byte_addr;
wire				c3_p0_cmd_empty;
wire				c3_p0_cmd_full;

wire				c3_p0_wr_clk;
wire				c3_p0_wr_en;
wire[C3_P0_MASK_SIZE-1:0]	c3_p0_wr_mask;
wire[C3_P0_DATA_PORT_SIZE-1:0]	c3_p0_wr_data;
wire				c3_p0_wr_full;
wire				c3_p0_wr_empty;
wire[6:0]			c3_p0_wr_count;
wire				c3_p0_wr_underrun;
wire				c3_p0_wr_error;

wire				c3_p0_rd_clk;
wire				c3_p0_rd_en;
wire[C3_P0_DATA_PORT_SIZE-1:0]	c3_p0_rd_data;
wire				c3_p0_rd_full;
wire				c3_p0_rd_empty;
wire[6:0]			c3_p0_rd_count;
wire				c3_p0_rd_overflow;
wire				c3_p0_rd_error;

wire				c3_p1_cmd_clk;
wire				c3_p1_cmd_en;
wire[2:0]			c3_p1_cmd_instr;
wire[5:0]			c3_p1_cmd_bl;
wire[29:0]			c3_p1_cmd_byte_addr;
wire				c3_p1_cmd_empty;
wire				c3_p1_cmd_full;

wire				c3_p1_wr_clk;
wire				c3_p1_wr_en;
wire[C3_P1_MASK_SIZE-1:0]	c3_p1_wr_mask;
wire[C3_P1_DATA_PORT_SIZE-1:0]	c3_p1_wr_data;
wire				c3_p1_wr_full;
wire				c3_p1_wr_empty;
wire[6:0]			c3_p1_wr_count;
wire				c3_p1_wr_underrun;
wire				c3_p1_wr_error;

wire				c3_p1_rd_clk;
wire				c3_p1_rd_en;
wire[C3_P1_DATA_PORT_SIZE-1:0]	c3_p1_rd_data;
wire				c3_p1_rd_full;
wire				c3_p1_rd_empty;
wire[6:0]			c3_p1_rd_count;
wire				c3_p1_rd_overflow;
wire				c3_p1_rd_error;


// OK Moved from mig external ports
wire        error;
wire        c3_selfrefresh_mode; // OK
reg         c1_aresetn;
reg         c3_aresetn;
reg         c4_aresetn;
reg         c5_aresetn;
assign error = c3_error;
assign c3_clk0 = 1'b0;
assign ddr2_cs_n = 1'b0;


// Controller-3 instantiation
      memc_wrapper #
      (
         .C_MEMCLK_PERIOD                (C3_MEMCLK_PERIOD),   
         .C_CALIB_SOFT_IP                (C3_CALIB_SOFT_IP),
         .C_SIMULATION                   (C3_SIMULATION),
         .C_ARB_NUM_TIME_SLOTS           (C3_ARB_NUM_TIME_SLOTS),
         .C_ARB_TIME_SLOT_0              (C3_ARB_TIME0_SLOT),
         .C_ARB_TIME_SLOT_1              (C3_ARB_TIME1_SLOT),
         .C_ARB_TIME_SLOT_2              (C3_ARB_TIME2_SLOT),
         .C_ARB_TIME_SLOT_3              (C3_ARB_TIME3_SLOT),
         .C_ARB_TIME_SLOT_4              (C3_ARB_TIME4_SLOT),
         .C_ARB_TIME_SLOT_5              (C3_ARB_TIME5_SLOT),
         .C_ARB_TIME_SLOT_6              (C3_ARB_TIME6_SLOT),
         .C_ARB_TIME_SLOT_7              (C3_ARB_TIME7_SLOT),
         .C_ARB_TIME_SLOT_8              (C3_ARB_TIME8_SLOT),
         .C_ARB_TIME_SLOT_9              (C3_ARB_TIME9_SLOT),
         .C_ARB_TIME_SLOT_10             (C3_ARB_TIME10_SLOT),
         .C_ARB_TIME_SLOT_11             (C3_ARB_TIME11_SLOT),
         .C_ARB_ALGORITHM                (C3_ARB_ALGORITHM),
         .C_PORT_ENABLE                  (C3_PORT_ENABLE),
         .C_PORT_CONFIG                  (C3_PORT_CONFIG),
         .C_MEM_TRAS                     (C3_MEM_TRAS),
         .C_MEM_TRCD                     (C3_MEM_TRCD),
         .C_MEM_TREFI                    (C3_MEM_TREFI),
         .C_MEM_TRFC                     (C3_MEM_TRFC),
         .C_MEM_TRP                      (C3_MEM_TRP),
         .C_MEM_TWR                      (C3_MEM_TWR),
         .C_MEM_TRTP                     (C3_MEM_TRTP),
         .C_MEM_TWTR                     (C3_MEM_TWTR),
         .C_MEM_ADDR_ORDER               (C3_MEM_ADDR_ORDER),
         .C_NUM_DQ_PINS                  (C3_NUM_DQ_PINS),
         .C_MEM_TYPE                     (C3_MEM_TYPE),
         .C_MEM_DENSITY                  (C3_MEM_DENSITY),
         .C_MEM_BURST_LEN                (C3_MEM_BURST_LEN),
         .C_MEM_CAS_LATENCY              (C3_MEM_CAS_LATENCY),
         .C_MEM_ADDR_WIDTH               (C3_MEM_ADDR_WIDTH),
         .C_MEM_BANKADDR_WIDTH           (C3_MEM_BANKADDR_WIDTH),
         .C_MEM_NUM_COL_BITS             (C3_MEM_NUM_COL_BITS),
         .C_MEM_DDR1_2_ODS               (C3_MEM_DDR1_2_ODS),
         .C_MEM_DDR2_RTT                 (C3_MEM_DDR2_RTT),
         .C_MEM_DDR2_DIFF_DQS_EN         (C3_MEM_DDR2_DIFF_DQS_EN),
         .C_MEM_DDR2_3_PA_SR             (C3_MEM_DDR2_3_PA_SR),
         .C_MEM_DDR2_3_HIGH_TEMP_SR      (C3_MEM_DDR2_3_HIGH_TEMP_SR),
         .C_MEM_DDR3_CAS_LATENCY         (C3_MEM_DDR3_CAS_LATENCY),
         .C_MEM_DDR3_ODS                 (C3_MEM_DDR3_ODS),
         .C_MEM_DDR3_RTT                 (C3_MEM_DDR3_RTT),
         .C_MEM_DDR3_CAS_WR_LATENCY      (C3_MEM_DDR3_CAS_WR_LATENCY),
         .C_MEM_DDR3_AUTO_SR             (C3_MEM_DDR3_AUTO_SR),
         .C_MEM_MOBILE_PA_SR             (C3_MEM_MOBILE_PA_SR),
         .C_MEM_MDDR_ODS                 (C3_MEM_MDDR_ODS),
         .C_MC_CALIB_BYPASS              (C3_MC_CALIB_BYPASS),
         .C_MC_CALIBRATION_MODE          (C3_MC_CALIBRATION_MODE),
         .C_MC_CALIBRATION_DELAY         (C3_MC_CALIBRATION_DELAY),
         .C_SKIP_IN_TERM_CAL             (C3_SKIP_IN_TERM_CAL),
         .C_SKIP_DYNAMIC_CAL             (C3_SKIP_DYNAMIC_CAL),
         .LDQSP_TAP_DELAY_VAL            (C3_LDQSP_TAP_DELAY_VAL),
         .UDQSP_TAP_DELAY_VAL            (C3_UDQSP_TAP_DELAY_VAL),
         .LDQSN_TAP_DELAY_VAL            (C3_LDQSN_TAP_DELAY_VAL),
         .UDQSN_TAP_DELAY_VAL            (C3_UDQSN_TAP_DELAY_VAL),
         .DQ0_TAP_DELAY_VAL              (C3_DQ0_TAP_DELAY_VAL),
         .DQ1_TAP_DELAY_VAL              (C3_DQ1_TAP_DELAY_VAL),
         .DQ2_TAP_DELAY_VAL              (C3_DQ2_TAP_DELAY_VAL),
         .DQ3_TAP_DELAY_VAL              (C3_DQ3_TAP_DELAY_VAL),
         .DQ4_TAP_DELAY_VAL              (C3_DQ4_TAP_DELAY_VAL),
         .DQ5_TAP_DELAY_VAL              (C3_DQ5_TAP_DELAY_VAL),
         .DQ6_TAP_DELAY_VAL              (C3_DQ6_TAP_DELAY_VAL),
         .DQ7_TAP_DELAY_VAL              (C3_DQ7_TAP_DELAY_VAL),
         .DQ8_TAP_DELAY_VAL              (C3_DQ8_TAP_DELAY_VAL),
         .DQ9_TAP_DELAY_VAL              (C3_DQ9_TAP_DELAY_VAL),
         .DQ10_TAP_DELAY_VAL             (C3_DQ10_TAP_DELAY_VAL),
         .DQ11_TAP_DELAY_VAL             (C3_DQ11_TAP_DELAY_VAL),
         .DQ12_TAP_DELAY_VAL             (C3_DQ12_TAP_DELAY_VAL),
         .DQ13_TAP_DELAY_VAL             (C3_DQ13_TAP_DELAY_VAL),
         .DQ14_TAP_DELAY_VAL             (C3_DQ14_TAP_DELAY_VAL),
         .DQ15_TAP_DELAY_VAL             (C3_DQ15_TAP_DELAY_VAL),
         .C_P0_MASK_SIZE                 (C3_P0_MASK_SIZE),
         .C_P0_DATA_PORT_SIZE            (C3_P0_DATA_PORT_SIZE),
         .C_P1_MASK_SIZE                 (C3_P1_MASK_SIZE),
         .C_P1_DATA_PORT_SIZE            (C3_P1_DATA_PORT_SIZE)
	) memc3_wrapper_inst (
         .mcbx_dram_addr                 (ddr2_a), 
         .mcbx_dram_ba                   (ddr2_ba),
         .mcbx_dram_ras_n                (ddr2_ras_n), 
         .mcbx_dram_cas_n                (ddr2_cas_n), 
         .mcbx_dram_we_n                 (ddr2_we_n), 
         .mcbx_dram_cke                  (ddr2_cke), 
         .mcbx_dram_clk                  (ddr2_ck), 
         .mcbx_dram_clk_n                (ddr2_ck_n), 
         .mcbx_dram_dq                   (ddr2_dq),
         .mcbx_dram_dqs                  (ddr2_dqs), 
         .mcbx_dram_dqs_n                (ddr2_dqs_n), 
         .mcbx_dram_udqs                 (ddr2_udqs), 
         .mcbx_dram_udqs_n               (ddr2_udqs_n), 
         .mcbx_dram_udm                  (ddr2_udm), 
         .mcbx_dram_ldm                  (ddr2_dm), 
         .mcbx_dram_odt                  (ddr2_odt), 
         .mcbx_dram_ddr3_rst             ( ), 
         .mcbx_rzq                       (ddr2_rzq),
         .mcbx_zio                       (ddr2_zio),
         .calib_done                     (calib_done),
         .async_rst                      (async_rst),
         .sysclk_2x                      (sysclk_2x), 
         .sysclk_2x_180                  (sysclk_2x_180), 
         .pll_ce_0                       (pll_ce_0),
         .pll_ce_90                      (pll_ce_90), 
         .pll_lock                       (pll_lock),
         .mcb_drp_clk                    (mcb_drp_clk), 
     
         // The following port map shows all the six logical user ports. However, all
	 // of them may not be active in this design. A port should be enabled to 
	 // validate its port map. If it is not,the complete port is going to float 
	 // by getting disconnected from the lower level MCB modules. The port enable
	 // information of a controller can be obtained from the corresponding local
	 // parameter CX_PORT_ENABLE. In such a case, we can simply ignore its port map.
	 // The following comments will explain when a port is going to be active.
	 // Config-1: Two 32-bit bi-directional and four 32-bit unidirectional ports
	 // Config-2: Four 32-bit bi-directional ports
	 // Config-3: One 64-bit bi-directional and two 32-bit bi-directional ports
	 // Config-4: Two 64-bit bi-directional ports
	 // Config-5: One 128-bit bi-directional port

         // User Port-0 command interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
         .p0_cmd_clk                     (p0_cmd_clk), 
         .p0_cmd_en                      (p0_cmd_en), 
         .p0_cmd_instr                   (p0_cmd_instr),
         .p0_cmd_bl                      (p0_cmd_bl), 
         .p0_cmd_byte_addr               (p0_cmd_byte_addr), 
         .p0_cmd_full                    (c3_p0_cmd_full),
         .p0_cmd_empty                   (c3_p0_cmd_empty),
         // User Port-0 data write interface will be active only when the port is enabled in
         // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
         .p0_wr_clk                      (p0_wr_clk), 
         .p0_wr_en                       (p0_wr_en),
         .p0_wr_mask                     (p0_wr_mask),
         .p0_wr_data                     (p0_wr_data),
         .p0_wr_full                     (c3_p0_wr_full),
         .p0_wr_count                    (c3_p0_wr_count),
         .p0_wr_empty                    (c3_p0_wr_empty),
         .p0_wr_underrun                 (c3_p0_wr_underrun),
         .p0_wr_error                    (c3_p0_wr_error),
         // User Port-0 data read interface will be active only when the port is enabled in
         // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
         .p0_rd_clk                      (c3_clk0), 
         .p0_rd_en                       (c3_p0_rd_en),
         .p0_rd_data                     (c3_p0_rd_data),
         .p0_rd_empty                    (c3_p0_rd_empty),
         .p0_rd_count                    (c3_p0_rd_count),
         .p0_rd_full                     (c3_p0_rd_full),
         .p0_rd_overflow                 (c3_p0_rd_overflow),
         .p0_rd_error                    (c3_p0_rd_error),
 
         // User Port-1 command interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2, Config-3 and Config-4
         .p1_cmd_clk                     (p1_cmd_clk), 
         .p1_cmd_en                      (p1_cmd_en), 
         .p1_cmd_instr                   (p1_cmd_instr),
         .p1_cmd_bl                      (p1_cmd_bl), 
         .p1_cmd_byte_addr               (p1_cmd_byte_addr), 
         .p1_cmd_full                    (c3_p1_cmd_full),
         .p1_cmd_empty                   (c3_p1_cmd_empty),
         // User Port-1 data write interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2, Config-3 and Config-4
         .p1_wr_clk                      (c3_clk0), 
         .p1_wr_en                       (c3_p1_wr_en),
         .p1_wr_mask                     (c3_p1_wr_mask),
         .p1_wr_data                     (c3_p1_wr_data),
         .p1_wr_full                     (c3_p1_wr_full),
         .p1_wr_count                    (c3_p1_wr_count),
         .p1_wr_empty                    (c3_p1_wr_empty),
         .p1_wr_underrun                 (c3_p1_wr_underrun),
         .p1_wr_error                    (c3_p1_wr_error),
         // User Port-1 data read interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2, Config-3 and Config-4
         .p1_rd_clk                      (p1_rd_clk), 
         .p1_rd_en                       (p1_rd_en),
         .p1_rd_data                     (p1_rd_data),
         .p1_rd_empty                    (p1_rd_empty),
         .p1_rd_count                    (c3_p1_rd_count),
         .p1_rd_full                     (c3_p1_rd_full),
         .p1_rd_overflow                 (c3_p1_rd_overflow),
         .p1_rd_error                    (c3_p1_rd_error),
         
         // OK removed unused port mappings
      
         .selfrefresh_enter              (1'b0), 
         .selfrefresh_mode               (c3_selfrefresh_mode)
      );

endmodule

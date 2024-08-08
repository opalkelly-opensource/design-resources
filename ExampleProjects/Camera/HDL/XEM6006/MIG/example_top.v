//*****************************************************************************
// (c) Copyright 2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 3.8
//  \   \         Application        : MIG
//  /   /         Filename           : example_top #.v
// /___/   /\     Date Last Modified : $Date$
// \   \  /  \    Date Created       : Tue Feb 23 2010
//  \___\/\___\
//
//Device           : Spartan-6
//Design Name      : DDR/DDR2/DDR3/LPDDR 
//Purpose          : This is a template file for the design top module. This module contains 
//                   all the four memory controllers and the two infrastructures. However,
//                   only the enabled modules will be active and others inactive.
//Reference        :
//Revision History :
//*****************************************************************************
`timescale 1ns/1ps

(* X_CORE_INFO = "mig_v3_8_ddr2_s6, Coregen 13.2" , CORE_GENERATION_INFO = "ddr2_s6,mig_v3_8,{component_name=ddr2, C1_MEM_INTERFACE_TYPE=DDR2_SDRAM, C1_CLK_PERIOD=3200, C1_MEMORY_PART=mt47h64m16xx-3, C1_MEMORY_DEVICE_WIDTH=16, C1_OUTPUT_DRV=FULL, C1_RTT_NOM=50OHMS, C1_DQS#_ENABLE=YES, C1_HIGH_TEMP_SR=NORMAL, C1_PORT_CONFIG=Two 64-bit bi-directional ports, C1_MEM_ADDR_ORDER=ROW_BANK_COLUMN, C1_PORT_ENABLE=Port0_Port1, C1_CLASS_ADDR=II, C1_CLASS_DATA=II, C1_INPUT_PIN_TERMINATION=CALIB_TERM, C1_DATA_TERMINATION=25 Ohms, C1_CLKFBOUT_MULT_F=2, C1_CLKOUT_DIVIDE=1, C1_DEBUG_PORT=0, INPUT_CLK_TYPE=Single-Ended, LANGUAGE=Verilog, SYNTHESIS_TOOL=Foundation_ISE, NO_OF_CONTROLLERS=1}" *)
module example_top #
(
   parameter C1_P0_MASK_SIZE           = 8,
   parameter C1_P0_DATA_PORT_SIZE      = 64,
   parameter C1_P1_MASK_SIZE           = 8,
   parameter C1_P1_DATA_PORT_SIZE      = 64,
   parameter DEBUG_EN                = 0,       
                                       // # = 1, Enable debug signals/controls,
                                       //   = 0, Disable debug signals/controls.
   parameter C1_MEMCLK_PERIOD        = 3200,       
                                       // Memory data transfer clock period
   parameter C1_CALIB_SOFT_IP        = "TRUE",       
                                       // # = TRUE, Enables the soft calibration logic,
                                       // # = FALSE, Disables the soft calibration logic.
   parameter C1_SIMULATION           = "FALSE",       
                                       // # = TRUE, Simulating the design. Useful to reduce the simulation time,
                                       // # = FALSE, Implementing the design.
   parameter C1_HW_TESTING           = "FALSE",       
                                       // Determines the address space accessed by the traffic generator,
                                       // # = FALSE, Smaller address space,
                                       // # = TRUE, Large address space.
   parameter C1_RST_ACT_LOW          = 0,       
                                       // # = 1 for active low reset,
                                       // # = 0 for active high reset.
   parameter C1_INPUT_CLK_TYPE       = "SINGLE_ENDED",       
                                       // input clock type DIFFERENTIAL or SINGLE_ENDED
   parameter C1_MEM_ADDR_ORDER       = "ROW_BANK_COLUMN",       
                                       // The order in which user address is provided to the memory controller,
                                       // ROW_BANK_COLUMN or BANK_ROW_COLUMN
   parameter C1_NUM_DQ_PINS          = 16,       
                                       // External memory data width
   parameter C1_MEM_ADDR_WIDTH       = 13,       
                                       // External memory address width
   parameter C1_MEM_BANKADDR_WIDTH   = 3        
                                       // External memory bank address width
)	

(
   output                                           calib_done,
   output                                           error,
   inout  [C1_NUM_DQ_PINS-1:0]                      mcb1_dram_dq,
   output [C1_MEM_ADDR_WIDTH-1:0]                   mcb1_dram_a,
   output [C1_MEM_BANKADDR_WIDTH-1:0]               mcb1_dram_ba,
   output                                           mcb1_dram_ras_n,
   output                                           mcb1_dram_cas_n,
   output                                           mcb1_dram_we_n,
   output                                           mcb1_dram_odt,
   output                                           mcb1_dram_cke,
   output                                           mcb1_dram_dm,
   inout                                            mcb1_dram_udqs,
   inout                                            mcb1_dram_udqs_n,
   inout                                            mcb1_rzq,
   inout                                            mcb1_zio,
   output                                           mcb1_dram_udm,
   input                                            c1_sys_clk,
   input                                            c1_sys_rst_i,
   inout                                            mcb1_dram_dqs,
   inout                                            mcb1_dram_dqs_n,
   output                                           mcb1_dram_ck,
   output                                           mcb1_dram_ck_n
);
// The parameter CX_PORT_ENABLE shows all the active user ports in the design.
// For example, the value 6'b111100 tells that only port-2, port-3, port-4
// and port-5 are enabled. The other two ports are inactive. An inactive port
// can be a disabled port or an invisible logical port. Few examples to the 
// invisible logical port are port-4 and port-5 in the user port configuration,
// Config-2: Four 32-bit bi-directional ports and the ports port-2 through
// port-5 in Config-4: Two 64-bit bi-directional ports. Please look into the 
// Chapter-2 of ug388.pdf in the /docs directory for further details.
   localparam C1_PORT_ENABLE              = 6'b000011;
   localparam C1_PORT_CONFIG             =  "B64_B64";
   localparam C1_P0_PORT_MODE             =  "BI_MODE";
   localparam C1_P1_PORT_MODE             =  "BI_MODE";
   localparam C1_P2_PORT_MODE             =  "NONE";
   localparam C1_P3_PORT_MODE             =  "NONE";
   localparam C1_P4_PORT_MODE             =  "NONE";
   localparam C1_P5_PORT_MODE             =  "NONE";
   localparam C1_CLKOUT0_DIVIDE       = 1;       
   localparam C1_CLKOUT1_DIVIDE       = 1;       
   localparam C1_CLKOUT2_DIVIDE       = 16;       
   localparam C1_CLKOUT3_DIVIDE       = 8;       
   localparam C1_CLKFBOUT_MULT        = 2;       
   localparam C1_DIVCLK_DIVIDE        = 1;       
   localparam C1_ARB_ALGORITHM        = 0;       
   localparam C1_ARB_NUM_TIME_SLOTS   = 12;       
   localparam C1_ARB_TIME_SLOT_0      = 6'o01;       
   localparam C1_ARB_TIME_SLOT_1      = 6'o10;       
   localparam C1_ARB_TIME_SLOT_2      = 6'o01;       
   localparam C1_ARB_TIME_SLOT_3      = 6'o10;       
   localparam C1_ARB_TIME_SLOT_4      = 6'o01;       
   localparam C1_ARB_TIME_SLOT_5      = 6'o10;       
   localparam C1_ARB_TIME_SLOT_6      = 6'o01;       
   localparam C1_ARB_TIME_SLOT_7      = 6'o10;       
   localparam C1_ARB_TIME_SLOT_8      = 6'o01;       
   localparam C1_ARB_TIME_SLOT_9      = 6'o10;       
   localparam C1_ARB_TIME_SLOT_10     = 6'o01;       
   localparam C1_ARB_TIME_SLOT_11     = 6'o10;       
   localparam C1_MEM_TRAS             = 40000;       
   localparam C1_MEM_TRCD             = 15000;       
   localparam C1_MEM_TREFI            = 7800000;       
   localparam C1_MEM_TRFC             = 127500;       
   localparam C1_MEM_TRP              = 15000;       
   localparam C1_MEM_TWR              = 15000;       
   localparam C1_MEM_TRTP             = 7500;       
   localparam C1_MEM_TWTR             = 7500;       
   localparam C1_MEM_TYPE             = "DDR2";       
   localparam C1_MEM_DENSITY          = "1Gb";       
   localparam C1_MEM_BURST_LEN        = 4;       
   localparam C1_MEM_CAS_LATENCY      = 5;       
   localparam C1_MEM_NUM_COL_BITS     = 10;       
   localparam C1_MEM_DDR1_2_ODS       = "FULL";       
   localparam C1_MEM_DDR2_RTT         = "50OHMS";       
   localparam C1_MEM_DDR2_DIFF_DQS_EN  = "YES";       
   localparam C1_MEM_DDR2_3_PA_SR     = "FULL";       
   localparam C1_MEM_DDR2_3_HIGH_TEMP_SR  = "NORMAL";       
   localparam C1_MEM_DDR3_CAS_LATENCY  = 6;       
   localparam C1_MEM_DDR3_ODS         = "DIV6";       
   localparam C1_MEM_DDR3_RTT         = "DIV2";       
   localparam C1_MEM_DDR3_CAS_WR_LATENCY  = 5;       
   localparam C1_MEM_DDR3_AUTO_SR     = "ENABLED";       
   localparam C1_MEM_MOBILE_PA_SR     = "FULL";       
   localparam C1_MEM_MDDR_ODS         = "FULL";       
   localparam C1_MC_CALIB_BYPASS      = "NO";       
   localparam C1_MC_CALIBRATION_MODE  = "CALIBRATION";       
   localparam C1_MC_CALIBRATION_DELAY  = "HALF";       
   localparam C1_SKIP_IN_TERM_CAL     = 0;       
   localparam C1_SKIP_DYNAMIC_CAL     = 0;       
   localparam C1_LDQSP_TAP_DELAY_VAL  = 0;       
   localparam C1_LDQSN_TAP_DELAY_VAL  = 0;       
   localparam C1_UDQSP_TAP_DELAY_VAL  = 0;       
   localparam C1_UDQSN_TAP_DELAY_VAL  = 0;       
   localparam C1_DQ0_TAP_DELAY_VAL    = 0;       
   localparam C1_DQ1_TAP_DELAY_VAL    = 0;       
   localparam C1_DQ2_TAP_DELAY_VAL    = 0;       
   localparam C1_DQ3_TAP_DELAY_VAL    = 0;       
   localparam C1_DQ4_TAP_DELAY_VAL    = 0;       
   localparam C1_DQ5_TAP_DELAY_VAL    = 0;       
   localparam C1_DQ6_TAP_DELAY_VAL    = 0;       
   localparam C1_DQ7_TAP_DELAY_VAL    = 0;       
   localparam C1_DQ8_TAP_DELAY_VAL    = 0;       
   localparam C1_DQ9_TAP_DELAY_VAL    = 0;       
   localparam C1_DQ10_TAP_DELAY_VAL   = 0;       
   localparam C1_DQ11_TAP_DELAY_VAL   = 0;       
   localparam C1_DQ12_TAP_DELAY_VAL   = 0;       
   localparam C1_DQ13_TAP_DELAY_VAL   = 0;       
   localparam C1_DQ14_TAP_DELAY_VAL   = 0;       
   localparam C1_DQ15_TAP_DELAY_VAL   = 0;       
   localparam C1_MCB_USE_EXTERNAL_BUFPLL  = 1;       
   localparam C1_SMALL_DEVICE         = "FALSE";       
   localparam C1_INCLK_PERIOD         = ((C1_MEMCLK_PERIOD * C1_CLKFBOUT_MULT) / (C1_DIVCLK_DIVIDE * C1_CLKOUT0_DIVIDE * 2));       
   localparam C1_p0_BEGIN_ADDRESS                   = (C1_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000200;
   localparam C1_p0_DATA_MODE                       = 4'b0010;
   localparam C1_p0_END_ADDRESS                     = (C1_HW_TESTING == "TRUE") ? 32'h02ffffff:32'h000003ff;
   localparam C1_p0_PRBS_EADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'hfc000000:32'hfffff800;
   localparam C1_p0_PRBS_SADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000200;
   localparam C1_p1_BEGIN_ADDRESS                   = (C1_HW_TESTING == "TRUE") ? 32'h03000000:32'h00000400;
   localparam C1_p1_DATA_MODE                       = 4'b0010;
   localparam C1_p1_END_ADDRESS                     = (C1_HW_TESTING == "TRUE") ? 32'h04ffffff:32'h000005ff;
   localparam C1_p1_PRBS_EADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff000;
   localparam C1_p1_PRBS_SADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'h03000000:32'h00000400;
   localparam C1_p2_BEGIN_ADDRESS                   = (C1_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000600;
   localparam C1_p2_DATA_MODE                       = 4'b0010;
   localparam C1_p2_END_ADDRESS                     = (C1_HW_TESTING == "TRUE") ? 32'h06ffffff:32'h000007ff;
   localparam C1_p2_PRBS_EADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff000;
   localparam C1_p2_PRBS_SADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000600;
   localparam C1_p3_BEGIN_ADDRESS                   = (C1_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000700;
   localparam C1_p3_DATA_MODE                       = 4'b0010;
   localparam C1_p3_END_ADDRESS                     = (C1_HW_TESTING == "TRUE") ? 32'h02ffffff:32'h000008ff;
   localparam C1_p3_PRBS_EADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'hfc000000:32'hfffff000;
   localparam C1_p3_PRBS_SADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000700;
   localparam C1_p4_BEGIN_ADDRESS                   = (C1_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;
   localparam C1_p4_DATA_MODE                       = 4'b0010;
   localparam C1_p4_END_ADDRESS                     = (C1_HW_TESTING == "TRUE") ? 32'h06ffffff:32'h000006ff;
   localparam C1_p4_PRBS_EADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff800;
   localparam C1_p4_PRBS_SADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;
   localparam C1_p5_BEGIN_ADDRESS                   = (C1_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;
   localparam C1_p5_DATA_MODE                       = 4'b0010;
   localparam C1_p5_END_ADDRESS                     = (C1_HW_TESTING == "TRUE") ? 32'h06ffffff:32'h000006ff;
   localparam C1_p5_PRBS_EADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'hf8000000:32'hfffff800;
   localparam C1_p5_PRBS_SADDR_MASK_POS             = (C1_HW_TESTING == "TRUE") ? 32'h05000000:32'h00000500;
   localparam DBG_WR_STS_WIDTH        = 32;
   localparam DBG_RD_STS_WIDTH        = 32;
   localparam C1_ARB_TIME0_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_0[5:3], C1_ARB_TIME_SLOT_0[2:0]};
   localparam C1_ARB_TIME1_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_1[5:3], C1_ARB_TIME_SLOT_1[2:0]};
   localparam C1_ARB_TIME2_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_2[5:3], C1_ARB_TIME_SLOT_2[2:0]};
   localparam C1_ARB_TIME3_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_3[5:3], C1_ARB_TIME_SLOT_3[2:0]};
   localparam C1_ARB_TIME4_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_4[5:3], C1_ARB_TIME_SLOT_4[2:0]};
   localparam C1_ARB_TIME5_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_5[5:3], C1_ARB_TIME_SLOT_5[2:0]};
   localparam C1_ARB_TIME6_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_6[5:3], C1_ARB_TIME_SLOT_6[2:0]};
   localparam C1_ARB_TIME7_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_7[5:3], C1_ARB_TIME_SLOT_7[2:0]};
   localparam C1_ARB_TIME8_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_8[5:3], C1_ARB_TIME_SLOT_8[2:0]};
   localparam C1_ARB_TIME9_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_9[5:3], C1_ARB_TIME_SLOT_9[2:0]};
   localparam C1_ARB_TIME10_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_10[5:3], C1_ARB_TIME_SLOT_10[2:0]};
   localparam C1_ARB_TIME11_SLOT  = {3'b000, 3'b000, 3'b000, 3'b000, C1_ARB_TIME_SLOT_11[5:3], C1_ARB_TIME_SLOT_11[2:0]};

  wire                              c1_sys_clk_p;
  wire                              c1_sys_clk_n;
  wire                              c1_error;
  wire                              c1_calib_done;
  wire                              c1_clk0;
  wire                              c1_rst0;
  wire                              c1_async_rst;
  wire                              c1_sysclk_2x;
  wire                              c1_sysclk_2x_180;
  wire                              c1_pll_ce_0;
  wire                              c1_pll_ce_90;
  wire                              c1_pll_lock;
  wire                              c1_mcb_drp_clk;
  wire                              c1_cmp_error;
  wire                              c1_cmp_data_valid;
  wire                              c1_vio_modify_enable;
  wire  [191:0]                                 c1_p0_error_status;
  wire  [191:0]                                 c1_p1_error_status;
  wire  [127:0]                                 c1_p2_error_status;
  wire  [127:0]                                 c1_p3_error_status;
  wire  [127:0]                                 c1_p4_error_status;
  wire  [127:0]                                 c1_p5_error_status;
  wire  [2:0]                      c1_vio_data_mode_value;
  wire  [2:0]                      c1_vio_addr_mode_value;
  wire  [31:0]                      c1_cmp_data;
wire				c1_p0_cmd_clk;
wire				c1_p0_cmd_en;
wire[2:0]			c1_p0_cmd_instr;
wire[5:0]			c1_p0_cmd_bl;
wire[29:0]			c1_p0_cmd_byte_addr;
wire				c1_p0_cmd_empty;
wire				c1_p0_cmd_full;

wire				c1_p0_wr_clk;
wire				c1_p0_wr_en;
wire[C1_P0_MASK_SIZE-1:0]	c1_p0_wr_mask;
wire[C1_P0_DATA_PORT_SIZE-1:0]	c1_p0_wr_data;
wire				c1_p0_wr_full;
wire				c1_p0_wr_empty;
wire[6:0]			c1_p0_wr_count;
wire				c1_p0_wr_underrun;
wire				c1_p0_wr_error;

wire				c1_p0_rd_clk;
wire				c1_p0_rd_en;
wire[C1_P0_DATA_PORT_SIZE-1:0]	c1_p0_rd_data;
wire				c1_p0_rd_full;
wire				c1_p0_rd_empty;
wire[6:0]			c1_p0_rd_count;
wire				c1_p0_rd_overflow;
wire				c1_p0_rd_error;

wire				c1_p1_cmd_clk;
wire				c1_p1_cmd_en;
wire[2:0]			c1_p1_cmd_instr;
wire[5:0]			c1_p1_cmd_bl;
wire[29:0]			c1_p1_cmd_byte_addr;
wire				c1_p1_cmd_empty;
wire				c1_p1_cmd_full;

wire				c1_p1_wr_clk;
wire				c1_p1_wr_en;
wire[C1_P1_MASK_SIZE-1:0]	c1_p1_wr_mask;
wire[C1_P1_DATA_PORT_SIZE-1:0]	c1_p1_wr_data;
wire				c1_p1_wr_full;
wire				c1_p1_wr_empty;
wire[6:0]			c1_p1_wr_count;
wire				c1_p1_wr_underrun;
wire				c1_p1_wr_error;

wire				c1_p1_rd_clk;
wire				c1_p1_rd_en;
wire[C1_P1_DATA_PORT_SIZE-1:0]	c1_p1_rd_data;
wire				c1_p1_rd_full;
wire				c1_p1_rd_empty;
wire[6:0]			c1_p1_rd_count;
wire				c1_p1_rd_overflow;
wire				c1_p1_rd_error;

wire				c1_p2_cmd_clk;
wire				c1_p2_cmd_en;
wire[2:0]			c1_p2_cmd_instr;
wire[5:0]			c1_p2_cmd_bl;
wire[29:0]			c1_p2_cmd_byte_addr;
wire				c1_p2_cmd_empty;
wire				c1_p2_cmd_full;

wire				c1_p2_wr_clk;
wire				c1_p2_wr_en;
wire[3:0]			c1_p2_wr_mask;
wire[31:0]			c1_p2_wr_data;
wire				c1_p2_wr_full;
wire				c1_p2_wr_empty;
wire[6:0]			c1_p2_wr_count;
wire				c1_p2_wr_underrun;
wire				c1_p2_wr_error;

wire				c1_p2_rd_clk;
wire				c1_p2_rd_en;
wire[31:0]			c1_p2_rd_data;
wire				c1_p2_rd_full;
wire				c1_p2_rd_empty;
wire[6:0]			c1_p2_rd_count;
wire				c1_p2_rd_overflow;
wire				c1_p2_rd_error;

wire				c1_p3_cmd_clk;
wire				c1_p3_cmd_en;
wire[2:0]			c1_p3_cmd_instr;
wire[5:0]			c1_p3_cmd_bl;
wire[29:0]			c1_p3_cmd_byte_addr;
wire				c1_p3_cmd_empty;
wire				c1_p3_cmd_full;

wire				c1_p3_wr_clk;
wire				c1_p3_wr_en;
wire[3:0]			c1_p3_wr_mask;
wire[31:0]			c1_p3_wr_data;
wire				c1_p3_wr_full;
wire				c1_p3_wr_empty;
wire[6:0]			c1_p3_wr_count;
wire				c1_p3_wr_underrun;
wire				c1_p3_wr_error;

wire				c1_p3_rd_clk;
wire				c1_p3_rd_en;
wire[31:0]			c1_p3_rd_data;
wire				c1_p3_rd_full;
wire				c1_p3_rd_empty;
wire[6:0]			c1_p3_rd_count;
wire				c1_p3_rd_overflow;
wire				c1_p3_rd_error;

wire				c1_p4_cmd_clk;
wire				c1_p4_cmd_en;
wire[2:0]			c1_p4_cmd_instr;
wire[5:0]			c1_p4_cmd_bl;
wire[29:0]			c1_p4_cmd_byte_addr;
wire				c1_p4_cmd_empty;
wire				c1_p4_cmd_full;

wire				c1_p4_wr_clk;
wire				c1_p4_wr_en;
wire[3:0]			c1_p4_wr_mask;
wire[31:0]			c1_p4_wr_data;
wire				c1_p4_wr_full;
wire				c1_p4_wr_empty;
wire[6:0]			c1_p4_wr_count;
wire				c1_p4_wr_underrun;
wire				c1_p4_wr_error;

wire				c1_p4_rd_clk;
wire				c1_p4_rd_en;
wire[31:0]			c1_p4_rd_data;
wire				c1_p4_rd_full;
wire				c1_p4_rd_empty;
wire[6:0]			c1_p4_rd_count;
wire				c1_p4_rd_overflow;
wire				c1_p4_rd_error;

wire				c1_p5_cmd_clk;
wire				c1_p5_cmd_en;
wire[2:0]			c1_p5_cmd_instr;
wire[5:0]			c1_p5_cmd_bl;
wire[29:0]			c1_p5_cmd_byte_addr;
wire				c1_p5_cmd_empty;
wire				c1_p5_cmd_full;

wire				c1_p5_wr_clk;
wire				c1_p5_wr_en;
wire[3:0]			c1_p5_wr_mask;
wire[31:0]			c1_p5_wr_data;
wire				c1_p5_wr_full;
wire				c1_p5_wr_empty;
wire[6:0]			c1_p5_wr_count;
wire				c1_p5_wr_underrun;
wire				c1_p5_wr_error;

wire				c1_p5_rd_clk;
wire				c1_p5_rd_en;
wire[31:0]			c1_p5_rd_data;
wire				c1_p5_rd_full;
wire				c1_p5_rd_empty;
wire[6:0]			c1_p5_rd_count;
wire				c1_p5_rd_overflow;
wire				c1_p5_rd_error;




   reg   c1_aresetn;
   reg   c3_aresetn;
   reg   c4_aresetn;
   reg   c5_aresetn;

assign error = c1_error;
assign calib_done = c1_calib_done;
assign  c1_sys_clk_p = 1'b0;
assign  c1_sys_clk_n = 1'b0;




// Infrastructure-1 instantiation
      infrastructure #
      (
         .C_INCLK_PERIOD                 (C1_INCLK_PERIOD),
         .C_RST_ACT_LOW                  (C1_RST_ACT_LOW),
         .C_INPUT_CLK_TYPE               (C1_INPUT_CLK_TYPE),
         .C_CLKOUT0_DIVIDE               (C1_CLKOUT0_DIVIDE),
         .C_CLKOUT1_DIVIDE               (C1_CLKOUT1_DIVIDE),
         .C_CLKOUT2_DIVIDE               (C1_CLKOUT2_DIVIDE),
         .C_CLKOUT3_DIVIDE               (C1_CLKOUT3_DIVIDE),
         .C_CLKFBOUT_MULT                (C1_CLKFBOUT_MULT),
         .C_DIVCLK_DIVIDE                (C1_DIVCLK_DIVIDE)
      )
      memc1_infrastructure_inst
      (
         .sys_clk_p                      (c1_sys_clk_p),  // [input] differential p type clock from board
         .sys_clk_n                      (c1_sys_clk_n),  // [input] differential n type clock from board
         .sys_clk                        (c1_sys_clk),    // [input] single ended input clock from board
         .sys_rst_i                      (c1_sys_rst_i),  
         .clk0                           (c1_clk0),       // [output] user clock which determines the operating frequency of user interface ports
         .rst0                           (c1_rst0),
         .async_rst                      (c1_async_rst),
         .sysclk_2x                      (c1_sysclk_2x),
         .sysclk_2x_180                  (c1_sysclk_2x_180),
         .pll_ce_0                       (c1_pll_ce_0),
         .pll_ce_90                      (c1_pll_ce_90),
         .pll_lock                       (c1_pll_lock),
         .mcb_drp_clk                    (c1_mcb_drp_clk)
      );
   

// Controller-1 instantiation
      memc_wrapper #
      (
         .C_MEMCLK_PERIOD                (C1_MEMCLK_PERIOD),   
         .C_CALIB_SOFT_IP                (C1_CALIB_SOFT_IP),
         //synthesis translate_off
         .C_SIMULATION                   (C1_SIMULATION),
         //synthesis translate_on
         .C_ARB_NUM_TIME_SLOTS           (C1_ARB_NUM_TIME_SLOTS),
         .C_ARB_TIME_SLOT_0              (C1_ARB_TIME0_SLOT),
         .C_ARB_TIME_SLOT_1              (C1_ARB_TIME1_SLOT),
         .C_ARB_TIME_SLOT_2              (C1_ARB_TIME2_SLOT),
         .C_ARB_TIME_SLOT_3              (C1_ARB_TIME3_SLOT),
         .C_ARB_TIME_SLOT_4              (C1_ARB_TIME4_SLOT),
         .C_ARB_TIME_SLOT_5              (C1_ARB_TIME5_SLOT),
         .C_ARB_TIME_SLOT_6              (C1_ARB_TIME6_SLOT),
         .C_ARB_TIME_SLOT_7              (C1_ARB_TIME7_SLOT),
         .C_ARB_TIME_SLOT_8              (C1_ARB_TIME8_SLOT),
         .C_ARB_TIME_SLOT_9              (C1_ARB_TIME9_SLOT),
         .C_ARB_TIME_SLOT_10             (C1_ARB_TIME10_SLOT),
         .C_ARB_TIME_SLOT_11             (C1_ARB_TIME11_SLOT),
         .C_ARB_ALGORITHM                (C1_ARB_ALGORITHM),
         .C_PORT_ENABLE                  (C1_PORT_ENABLE),
         .C_PORT_CONFIG                  (C1_PORT_CONFIG),
         .C_MEM_TRAS                     (C1_MEM_TRAS),
         .C_MEM_TRCD                     (C1_MEM_TRCD),
         .C_MEM_TREFI                    (C1_MEM_TREFI),
         .C_MEM_TRFC                     (C1_MEM_TRFC),
         .C_MEM_TRP                      (C1_MEM_TRP),
         .C_MEM_TWR                      (C1_MEM_TWR),
         .C_MEM_TRTP                     (C1_MEM_TRTP),
         .C_MEM_TWTR                     (C1_MEM_TWTR),
         .C_MEM_ADDR_ORDER               (C1_MEM_ADDR_ORDER),
         .C_NUM_DQ_PINS                  (C1_NUM_DQ_PINS),
         .C_MEM_TYPE                     (C1_MEM_TYPE),
         .C_MEM_DENSITY                  (C1_MEM_DENSITY),
         .C_MEM_BURST_LEN                (C1_MEM_BURST_LEN),
         .C_MEM_CAS_LATENCY              (C1_MEM_CAS_LATENCY),
         .C_MEM_ADDR_WIDTH               (C1_MEM_ADDR_WIDTH),
         .C_MEM_BANKADDR_WIDTH           (C1_MEM_BANKADDR_WIDTH),
         .C_MEM_NUM_COL_BITS             (C1_MEM_NUM_COL_BITS),
         .C_MEM_DDR1_2_ODS               (C1_MEM_DDR1_2_ODS),
         .C_MEM_DDR2_RTT                 (C1_MEM_DDR2_RTT),
         .C_MEM_DDR2_DIFF_DQS_EN         (C1_MEM_DDR2_DIFF_DQS_EN),
         .C_MEM_DDR2_3_PA_SR             (C1_MEM_DDR2_3_PA_SR),
         .C_MEM_DDR2_3_HIGH_TEMP_SR      (C1_MEM_DDR2_3_HIGH_TEMP_SR),
         .C_MEM_DDR3_CAS_LATENCY         (C1_MEM_DDR3_CAS_LATENCY),
         .C_MEM_DDR3_ODS                 (C1_MEM_DDR3_ODS),
         .C_MEM_DDR3_RTT                 (C1_MEM_DDR3_RTT),
         .C_MEM_DDR3_CAS_WR_LATENCY      (C1_MEM_DDR3_CAS_WR_LATENCY),
         .C_MEM_DDR3_AUTO_SR             (C1_MEM_DDR3_AUTO_SR),
         .C_MEM_MOBILE_PA_SR             (C1_MEM_MOBILE_PA_SR),
         .C_MEM_MDDR_ODS                 (C1_MEM_MDDR_ODS),
         .C_MC_CALIB_BYPASS              (C1_MC_CALIB_BYPASS),
         .C_MC_CALIBRATION_MODE          (C1_MC_CALIBRATION_MODE),
         .C_MC_CALIBRATION_DELAY         (C1_MC_CALIBRATION_DELAY),
         .C_SKIP_IN_TERM_CAL             (C1_SKIP_IN_TERM_CAL),
         .C_SKIP_DYNAMIC_CAL             (C1_SKIP_DYNAMIC_CAL),
         .LDQSP_TAP_DELAY_VAL            (C1_LDQSP_TAP_DELAY_VAL),
         .UDQSP_TAP_DELAY_VAL            (C1_UDQSP_TAP_DELAY_VAL),
         .LDQSN_TAP_DELAY_VAL            (C1_LDQSN_TAP_DELAY_VAL),
         .UDQSN_TAP_DELAY_VAL            (C1_UDQSN_TAP_DELAY_VAL),
         .DQ0_TAP_DELAY_VAL              (C1_DQ0_TAP_DELAY_VAL),
         .DQ1_TAP_DELAY_VAL              (C1_DQ1_TAP_DELAY_VAL),
         .DQ2_TAP_DELAY_VAL              (C1_DQ2_TAP_DELAY_VAL),
         .DQ3_TAP_DELAY_VAL              (C1_DQ3_TAP_DELAY_VAL),
         .DQ4_TAP_DELAY_VAL              (C1_DQ4_TAP_DELAY_VAL),
         .DQ5_TAP_DELAY_VAL              (C1_DQ5_TAP_DELAY_VAL),
         .DQ6_TAP_DELAY_VAL              (C1_DQ6_TAP_DELAY_VAL),
         .DQ7_TAP_DELAY_VAL              (C1_DQ7_TAP_DELAY_VAL),
         .DQ8_TAP_DELAY_VAL              (C1_DQ8_TAP_DELAY_VAL),
         .DQ9_TAP_DELAY_VAL              (C1_DQ9_TAP_DELAY_VAL),
         .DQ10_TAP_DELAY_VAL             (C1_DQ10_TAP_DELAY_VAL),
         .DQ11_TAP_DELAY_VAL             (C1_DQ11_TAP_DELAY_VAL),
         .DQ12_TAP_DELAY_VAL             (C1_DQ12_TAP_DELAY_VAL),
         .DQ13_TAP_DELAY_VAL             (C1_DQ13_TAP_DELAY_VAL),
         .DQ14_TAP_DELAY_VAL             (C1_DQ14_TAP_DELAY_VAL),
         .DQ15_TAP_DELAY_VAL             (C1_DQ15_TAP_DELAY_VAL),
         .C_P0_MASK_SIZE                 (C1_P0_MASK_SIZE),
         .C_P0_DATA_PORT_SIZE            (C1_P0_DATA_PORT_SIZE),
         .C_P1_MASK_SIZE                 (C1_P1_MASK_SIZE),
         .C_P1_DATA_PORT_SIZE            (C1_P1_DATA_PORT_SIZE)
	)
      
      memc1_wrapper_inst
      (
         .mcbx_dram_addr                 (mcb1_dram_a), 
         .mcbx_dram_ba                   (mcb1_dram_ba),
         .mcbx_dram_ras_n                (mcb1_dram_ras_n), 
         .mcbx_dram_cas_n                (mcb1_dram_cas_n), 
         .mcbx_dram_we_n                 (mcb1_dram_we_n), 
         .mcbx_dram_cke                  (mcb1_dram_cke), 
         .mcbx_dram_clk                  (mcb1_dram_ck), 
         .mcbx_dram_clk_n                (mcb1_dram_ck_n), 
         .mcbx_dram_dq                   (mcb1_dram_dq),
         .mcbx_dram_dqs                  (mcb1_dram_dqs), 
         .mcbx_dram_dqs_n                (mcb1_dram_dqs_n), 
         .mcbx_dram_udqs                 (mcb1_dram_udqs), 
         .mcbx_dram_udqs_n               (mcb1_dram_udqs_n), 
         .mcbx_dram_udm                  (mcb1_dram_udm), 
         .mcbx_dram_ldm                  (mcb1_dram_dm), 
         .mcbx_dram_odt                  (mcb1_dram_odt), 
         .mcbx_dram_ddr3_rst             ( ), 
         .mcbx_rzq                       (mcb1_rzq),
         .mcbx_zio                       (mcb1_zio),
         .calib_done                     (c1_calib_done),
         .async_rst                      (c1_async_rst),
         .sysclk_2x                      (c1_sysclk_2x), 
         .sysclk_2x_180                  (c1_sysclk_2x_180), 
         .pll_ce_0                       (c1_pll_ce_0),
         .pll_ce_90                      (c1_pll_ce_90), 
         .pll_lock                       (c1_pll_lock),
         .mcb_drp_clk                    (c1_mcb_drp_clk), 
     
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
         .p0_cmd_clk                     (c1_clk0), 
         .p0_cmd_en                      (c1_p0_cmd_en), 
         .p0_cmd_instr                   (c1_p0_cmd_instr),
         .p0_cmd_bl                      (c1_p0_cmd_bl), 
         .p0_cmd_byte_addr               (c1_p0_cmd_byte_addr), 
         .p0_cmd_full                    (c1_p0_cmd_full),
         .p0_cmd_empty                   (c1_p0_cmd_empty),
         // User Port-0 data write interface will be active only when the port is enabled in
         // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
         .p0_wr_clk                      (c1_clk0), 
         .p0_wr_en                       (c1_p0_wr_en),
         .p0_wr_mask                     (c1_p0_wr_mask),
         .p0_wr_data                     (c1_p0_wr_data),
         .p0_wr_full                     (c1_p0_wr_full),
         .p0_wr_count                    (c1_p0_wr_count),
         .p0_wr_empty                    (c1_p0_wr_empty),
         .p0_wr_underrun                 (c1_p0_wr_underrun),
         .p0_wr_error                    (c1_p0_wr_error),
         // User Port-0 data read interface will be active only when the port is enabled in
         // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
         .p0_rd_clk                      (c1_clk0), 
         .p0_rd_en                       (c1_p0_rd_en),
         .p0_rd_data                     (c1_p0_rd_data),
         .p0_rd_empty                    (c1_p0_rd_empty),
         .p0_rd_count                    (c1_p0_rd_count),
         .p0_rd_full                     (c1_p0_rd_full),
         .p0_rd_overflow                 (c1_p0_rd_overflow),
         .p0_rd_error                    (c1_p0_rd_error),
 
         // User Port-1 command interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2, Config-3 and Config-4
         .p1_cmd_clk                     (c1_clk0), 
         .p1_cmd_en                      (c1_p1_cmd_en), 
         .p1_cmd_instr                   (c1_p1_cmd_instr),
         .p1_cmd_bl                      (c1_p1_cmd_bl), 
         .p1_cmd_byte_addr               (c1_p1_cmd_byte_addr), 
         .p1_cmd_full                    (c1_p1_cmd_full),
         .p1_cmd_empty                   (c1_p1_cmd_empty),
         // User Port-1 data write interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2, Config-3 and Config-4
         .p1_wr_clk                      (c1_clk0), 
         .p1_wr_en                       (c1_p1_wr_en),
         .p1_wr_mask                     (c1_p1_wr_mask),
         .p1_wr_data                     (c1_p1_wr_data),
         .p1_wr_full                     (c1_p1_wr_full),
         .p1_wr_count                    (c1_p1_wr_count),
         .p1_wr_empty                    (c1_p1_wr_empty),
         .p1_wr_underrun                 (c1_p1_wr_underrun),
         .p1_wr_error                    (c1_p1_wr_error),
         // User Port-1 data read interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2, Config-3 and Config-4
         .p1_rd_clk                      (c1_clk0), 
         .p1_rd_en                       (c1_p1_rd_en),
         .p1_rd_data                     (c1_p1_rd_data),
         .p1_rd_empty                    (c1_p1_rd_empty),
         .p1_rd_count                    (c1_p1_rd_count),
         .p1_rd_full                     (c1_p1_rd_full),
         .p1_rd_overflow                 (c1_p1_rd_overflow),
         .p1_rd_error                    (c1_p1_rd_error),
      
         // User Port-2 command interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2 and Config-3
         .p2_cmd_clk                     (c1_clk0), 
         .p2_cmd_en                      (c1_p2_cmd_en), 
         .p2_cmd_instr                   (c1_p2_cmd_instr),
         .p2_cmd_bl                      (c1_p2_cmd_bl), 
         .p2_cmd_byte_addr               (c1_p2_cmd_byte_addr), 
         .p2_cmd_full                    (c1_p2_cmd_full),
         .p2_cmd_empty                   (c1_p2_cmd_empty),
         // User Port-2 data write interface will be active only when the port is enabled in 
         // the port configurations Config-1 write direction, Config-2 and Config-3
         .p2_wr_clk                      (c1_clk0), 
         .p2_wr_en                       (c1_p2_wr_en),
         .p2_wr_mask                     (c1_p2_wr_mask),
         .p2_wr_data                     (c1_p2_wr_data),
         .p2_wr_full                     (c1_p2_wr_full),
         .p2_wr_count                    (c1_p2_wr_count),
         .p2_wr_empty                    (c1_p2_wr_empty),
         .p2_wr_underrun                 (c1_p2_wr_underrun),
         .p2_wr_error                    (c1_p2_wr_error),
         // User Port-2 data read interface will be active only when the port is enabled in 
         // the port configurations Config-1 read direction, Config-2 and Config-3
         .p2_rd_clk                      (c1_clk0), 
         .p2_rd_en                       (c1_p2_rd_en),
         .p2_rd_data                     (c1_p2_rd_data),
         .p2_rd_empty                    (c1_p2_rd_empty),
         .p2_rd_count                    (c1_p2_rd_count),
         .p2_rd_full                     (c1_p2_rd_full),
         .p2_rd_overflow                 (c1_p2_rd_overflow),
         .p2_rd_error                    (c1_p2_rd_error),
      
         // User Port-3 command interface will be active only when the port is enabled in 
         // the port configurations Config-1 and Config-2
         .p3_cmd_clk                     (c1_clk0), 
         .p3_cmd_en                      (c1_p3_cmd_en), 
         .p3_cmd_instr                   (c1_p3_cmd_instr),
         .p3_cmd_bl                      (c1_p3_cmd_bl), 
         .p3_cmd_byte_addr               (c1_p3_cmd_byte_addr), 
         .p3_cmd_full                    (c1_p3_cmd_full),
         .p3_cmd_empty                   (c1_p3_cmd_empty),
         // User Port-3 data write interface will be active only when the port is enabled in 
         // the port configurations Config-1 write direction and Config-2
         .p3_wr_clk                      (c1_clk0), 
         .p3_wr_en                       (c1_p3_wr_en),
         .p3_wr_mask                     (c1_p3_wr_mask),
         .p3_wr_data                     (c1_p3_wr_data),
         .p3_wr_full                     (c1_p3_wr_full),
         .p3_wr_count                    (c1_p3_wr_count),
         .p3_wr_empty                    (c1_p3_wr_empty),
         .p3_wr_underrun                 (c1_p3_wr_underrun),
         .p3_wr_error                    (c1_p3_wr_error),
         // User Port-3 data read interface will be active only when the port is enabled in 
         // the port configurations Config-1 read direction and Config-2
         .p3_rd_clk                      (c1_clk0), 
         .p3_rd_en                       (c1_p3_rd_en),
         .p3_rd_data                     (c1_p3_rd_data),
         .p3_rd_empty                    (c1_p3_rd_empty),
         .p3_rd_count                    (c1_p3_rd_count),
         .p3_rd_full                     (c1_p3_rd_full),
         .p3_rd_overflow                 (c1_p3_rd_overflow),
         .p3_rd_error                    (c1_p3_rd_error),
      
         // User Port-4 command interface will be active only when the port is enabled in 
         // the port configuration Config-1
         .p4_cmd_clk                     (c1_clk0), 
         .p4_cmd_en                      (c1_p4_cmd_en), 
         .p4_cmd_instr                   (c1_p4_cmd_instr),
         .p4_cmd_bl                      (c1_p4_cmd_bl), 
         .p4_cmd_byte_addr               (c1_p4_cmd_byte_addr), 
         .p4_cmd_full                    (c1_p4_cmd_full),
         .p4_cmd_empty                   (c1_p4_cmd_empty),
         // User Port-4 data write interface will be active only when the port is enabled in 
         // the port configuration Config-1 write direction
         .p4_wr_clk                      (c1_clk0), 
         .p4_wr_en                       (c1_p4_wr_en),
         .p4_wr_mask                     (c1_p4_wr_mask),
         .p4_wr_data                     (c1_p4_wr_data),
         .p4_wr_full                     (c1_p4_wr_full),
         .p4_wr_count                    (c1_p4_wr_count),
         .p4_wr_empty                    (c1_p4_wr_empty),
         .p4_wr_underrun                 (c1_p4_wr_underrun),
         .p4_wr_error                    (c1_p4_wr_error),
         // User Port-4 data read interface will be active only when the port is enabled in 
         // the port configuration Config-1 read direction
         .p4_rd_clk                      (c1_clk0), 
         .p4_rd_en                       (c1_p4_rd_en),
         .p4_rd_data                     (c1_p4_rd_data),
         .p4_rd_empty                    (c1_p4_rd_empty),
         .p4_rd_count                    (c1_p4_rd_count),
         .p4_rd_full                     (c1_p4_rd_full),
         .p4_rd_overflow                 (c1_p4_rd_overflow),
         .p4_rd_error                    (c1_p4_rd_error),
      
         // User Port-5 command interface will be active only when the port is enabled in 
         // the port configuration Config-1
         .p5_cmd_clk                     (c1_clk0), 
         .p5_cmd_en                      (c1_p5_cmd_en), 
         .p5_cmd_instr                   (c1_p5_cmd_instr),
         .p5_cmd_bl                      (c1_p5_cmd_bl), 
         .p5_cmd_byte_addr               (c1_p5_cmd_byte_addr), 
         .p5_cmd_full                    (c1_p5_cmd_full),
         .p5_cmd_empty                   (c1_p5_cmd_empty),
         // User Port-5 data write interface will be active only when the port is enabled in 
         // the port configuration Config-1 write direction
         .p5_wr_clk                      (c1_clk0), 
         .p5_wr_en                       (c1_p5_wr_en),
         .p5_wr_mask                     (c1_p5_wr_mask),
         .p5_wr_data                     (c1_p5_wr_data),
         .p5_wr_full                     (c1_p5_wr_full),
         .p5_wr_count                    (c1_p5_wr_count),
         .p5_wr_empty                    (c1_p5_wr_empty),
         .p5_wr_underrun                 (c1_p5_wr_underrun),
         .p5_wr_error                    (c1_p5_wr_error),
         // User Port-5 data read interface will be active only when the port is enabled in 
         // the port configuration Config-1 read direction
         .p5_rd_clk                      (c1_clk0), 
         .p5_rd_en                       (c1_p5_rd_en),
         .p5_rd_data                     (c1_p5_rd_data),
         .p5_rd_empty                    (c1_p5_rd_empty),
         .p5_rd_count                    (c1_p5_rd_count),
         .p5_rd_full                     (c1_p5_rd_full),
         .p5_rd_overflow                 (c1_p5_rd_overflow),
         .p5_rd_error                    (c1_p5_rd_error),

         .selfrefresh_enter              (1'b0), 
         .selfrefresh_mode               (c1_selfrefresh_mode)
      );
   
// Test bench top for the controller-1
      memc_tb_top #
      (
         .C_SIMULATION                   (C1_SIMULATION),
         .C_NUM_DQ_PINS                  (C1_NUM_DQ_PINS),
         .C_MEM_BURST_LEN                (C1_MEM_BURST_LEN),
         .C_MEM_NUM_COL_BITS             (C1_MEM_NUM_COL_BITS),
         .C_SMALL_DEVICE                 (C1_SMALL_DEVICE),

         // The following parameters from C_PORT_ENABLE to C_P5_PORT_MODE are introduced
         // to handle the static instances of all the six traffic generators inside the
   	     // memc_tb_top module. 
         .C_PORT_ENABLE                  (C1_PORT_ENABLE),
         .C_P0_MASK_SIZE                 (C1_P0_MASK_SIZE),
         .C_P0_DATA_PORT_SIZE            (C1_P0_DATA_PORT_SIZE),
         .C_P1_MASK_SIZE                 (C1_P1_MASK_SIZE),
         .C_P1_DATA_PORT_SIZE            (C1_P1_DATA_PORT_SIZE),
         .C_P0_PORT_MODE                 (C1_P0_PORT_MODE),  
         .C_P1_PORT_MODE                 (C1_P1_PORT_MODE),  
         .C_P2_PORT_MODE                 (C1_P2_PORT_MODE),  
         .C_P3_PORT_MODE                 (C1_P3_PORT_MODE),
         .C_P4_PORT_MODE                 (C1_P4_PORT_MODE),
         .C_P5_PORT_MODE                 (C1_P5_PORT_MODE),

         .C_p0_BEGIN_ADDRESS             (C1_p0_BEGIN_ADDRESS),
         .C_p0_DATA_MODE                 (C1_p0_DATA_MODE),
         .C_p0_END_ADDRESS               (C1_p0_END_ADDRESS),
         .C_p0_PRBS_EADDR_MASK_POS       (C1_p0_PRBS_EADDR_MASK_POS),
         .C_p0_PRBS_SADDR_MASK_POS       (C1_p0_PRBS_SADDR_MASK_POS),
         .C_p1_BEGIN_ADDRESS             (C1_p1_BEGIN_ADDRESS),
         .C_p1_DATA_MODE                 (C1_p1_DATA_MODE),
         .C_p1_END_ADDRESS               (C1_p1_END_ADDRESS),
         .C_p1_PRBS_EADDR_MASK_POS       (C1_p1_PRBS_EADDR_MASK_POS),
         .C_p1_PRBS_SADDR_MASK_POS       (C1_p1_PRBS_SADDR_MASK_POS),
         .C_p2_BEGIN_ADDRESS             (C1_p2_BEGIN_ADDRESS),
         .C_p2_DATA_MODE                 (C1_p2_DATA_MODE),
         .C_p2_END_ADDRESS               (C1_p2_END_ADDRESS),
         .C_p2_PRBS_EADDR_MASK_POS       (C1_p2_PRBS_EADDR_MASK_POS),
         .C_p2_PRBS_SADDR_MASK_POS       (C1_p2_PRBS_SADDR_MASK_POS),
         .C_p3_BEGIN_ADDRESS             (C1_p3_BEGIN_ADDRESS),
         .C_p3_DATA_MODE                 (C1_p3_DATA_MODE),
         .C_p3_END_ADDRESS               (C1_p3_END_ADDRESS),
         .C_p3_PRBS_EADDR_MASK_POS       (C1_p3_PRBS_EADDR_MASK_POS),
         .C_p3_PRBS_SADDR_MASK_POS       (C1_p3_PRBS_SADDR_MASK_POS),
         .C_p4_BEGIN_ADDRESS             (C1_p4_BEGIN_ADDRESS),
         .C_p4_DATA_MODE                 (C1_p4_DATA_MODE),
         .C_p4_END_ADDRESS               (C1_p4_END_ADDRESS),
         .C_p4_PRBS_EADDR_MASK_POS       (C1_p4_PRBS_EADDR_MASK_POS),
         .C_p4_PRBS_SADDR_MASK_POS       (C1_p4_PRBS_SADDR_MASK_POS),
         .C_p5_BEGIN_ADDRESS             (C1_p5_BEGIN_ADDRESS),
         .C_p5_DATA_MODE                 (C1_p5_DATA_MODE),
         .C_p5_END_ADDRESS               (C1_p5_END_ADDRESS),
         .C_p5_PRBS_EADDR_MASK_POS       (C1_p5_PRBS_EADDR_MASK_POS),
         .C_p5_PRBS_SADDR_MASK_POS       (C1_p5_PRBS_SADDR_MASK_POS)
         )
      memc1_tb_top_inst
      (
         .error			                 (c1_error),
         .calib_done			         (c1_calib_done), 
         .clk0			                 (c1_clk0),
         .rst0			                 (c1_rst0),
         .cmp_error			             (c1_cmp_error),
         .cmp_data_valid  	             (c1_cmp_data_valid),
         .cmp_data			             (c1_cmp_data),
         .vio_modify_enable              (c1_vio_modify_enable),
         .vio_data_mode_value            (c1_vio_data_mode_value),
         .vio_addr_mode_value            (c1_vio_addr_mode_value),
         .p0_error_status	             (c1_p0_error_status),
         .p1_error_status	             (c1_p1_error_status),
         .p2_error_status	             (c1_p2_error_status),
         .p3_error_status	             (c1_p3_error_status),
         .p4_error_status	             (c1_p4_error_status),
         .p5_error_status	             (c1_p5_error_status),

  	     // The following port map shows that all the memory controller ports are connected
         // to the test bench top. However, a traffic generator can be connected to the 
         // corresponding port only if the port is enabled, whose information can be obtained
         // from the parameters C_PORT_ENABLE.

         // User Port-0 command interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
         .p0_mcb_cmd_en                  (c1_p0_cmd_en),
         .p0_mcb_cmd_instr               (c1_p0_cmd_instr),
         .p0_mcb_cmd_bl                  (c1_p0_cmd_bl),
         .p0_mcb_cmd_addr                (c1_p0_cmd_byte_addr),
         .p0_mcb_cmd_full                (c1_p0_cmd_full),
         // User Port-0 data write interface will be active only when the port is enabled in
         // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
         .p0_mcb_wr_en                   (c1_p0_wr_en),
         .p0_mcb_wr_mask                 (c1_p0_wr_mask),
         .p0_mcb_wr_data                 (c1_p0_wr_data),
         .p0_mcb_wr_full                 (c1_p0_wr_full),
         .p0_mcb_wr_fifo_counts          (c1_p0_wr_count),
         // User Port-0 data read interface will be active only when the port is enabled in
         // the port configurations Config-1, Config-2, Config-3, Config-4 and Config-5
         .p0_mcb_rd_en                   (c1_p0_rd_en),
         .p0_mcb_rd_data                 (c1_p0_rd_data),
         .p0_mcb_rd_empty                (c1_p0_rd_empty),
         .p0_mcb_rd_fifo_counts          (c1_p0_rd_count),

         // User Port-1 command interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2, Config-3 and Config-4
         .p1_mcb_cmd_en                  (c1_p1_cmd_en),
         .p1_mcb_cmd_instr               (c1_p1_cmd_instr),
         .p1_mcb_cmd_bl                  (c1_p1_cmd_bl),
         .p1_mcb_cmd_addr                (c1_p1_cmd_byte_addr),
         .p1_mcb_cmd_full                (c1_p1_cmd_full),
         // User Port-1 data write interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2, Config-3 and Config-4
         .p1_mcb_wr_en                   (c1_p1_wr_en),
         .p1_mcb_wr_mask                 (c1_p1_wr_mask),
         .p1_mcb_wr_data                 (c1_p1_wr_data),
         .p1_mcb_wr_full                 (c1_p1_wr_full),
         .p1_mcb_wr_fifo_counts          (c1_p1_wr_count),
         // User Port-1 data read interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2, Config-3 and Config-4
         .p1_mcb_rd_en                   (c1_p1_rd_en),
         .p1_mcb_rd_data                 (c1_p1_rd_data),
         .p1_mcb_rd_empty                (c1_p1_rd_empty),
         .p1_mcb_rd_fifo_counts          (c1_p1_rd_count),

         // User Port-2 command interface will be active only when the port is enabled in 
         // the port configurations Config-1, Config-2 and Config-3
         .p2_mcb_cmd_en                  (c1_p2_cmd_en),
         .p2_mcb_cmd_instr               (c1_p2_cmd_instr),
         .p2_mcb_cmd_bl                  (c1_p2_cmd_bl),
         .p2_mcb_cmd_addr                (c1_p2_cmd_byte_addr),
         .p2_mcb_cmd_full                (c1_p2_cmd_full),
         // User Port-2 data write interface will be active only when the port is enabled in 
         // the port configurations Config-1 write direction, Config-2 and Config-3
         .p2_mcb_wr_en                   (c1_p2_wr_en),
         .p2_mcb_wr_mask                 (c1_p2_wr_mask),
         .p2_mcb_wr_data                 (c1_p2_wr_data),
         .p2_mcb_wr_full                 (c1_p2_wr_full),
         .p2_mcb_wr_fifo_counts          (c1_p2_wr_count),
         // User Port-2 data read interface will be active only when the port is enabled in 
         // the port configurations Config-1 read direction, Config-2 and Config-3
         .p2_mcb_rd_en                   (c1_p2_rd_en),
         .p2_mcb_rd_data                 (c1_p2_rd_data),
         .p2_mcb_rd_empty                (c1_p2_rd_empty),
         .p2_mcb_rd_fifo_counts          (c1_p2_rd_count),

         // User Port-3 command interface will be active only when the port is enabled in 
         // the port configurations Config-1 and Config-2
         .p3_mcb_cmd_en                  (c1_p3_cmd_en),
         .p3_mcb_cmd_instr               (c1_p3_cmd_instr),
         .p3_mcb_cmd_bl                  (c1_p3_cmd_bl),
         .p3_mcb_cmd_addr                (c1_p3_cmd_byte_addr),
         .p3_mcb_cmd_full                (c1_p3_cmd_full),
         // User Port-3 data write interface will be active only when the port is enabled in 
         // the port configurations Config-1 write direction and Config-2
         .p3_mcb_wr_en                   (c1_p3_wr_en),
         .p3_mcb_wr_mask                 (c1_p3_wr_mask),
         .p3_mcb_wr_data                 (c1_p3_wr_data),
         .p3_mcb_wr_full                 (c1_p3_wr_full),
         .p3_mcb_wr_fifo_counts          (c1_p3_wr_count),
         // User Port-3 data read interface will be active only when the port is enabled in 
         // the port configurations Config-1 read direction and Config-2
         .p3_mcb_rd_en                   (c1_p3_rd_en),
         .p3_mcb_rd_data                 (c1_p3_rd_data),
         .p3_mcb_rd_empty                (c1_p3_rd_empty),
         .p3_mcb_rd_fifo_counts          (c1_p3_rd_count),

         // User Port-4 command interface will be active only when the port is enabled in 
         // the port configuration Config-1
         .p4_mcb_cmd_en                  (c1_p4_cmd_en),
         .p4_mcb_cmd_instr               (c1_p4_cmd_instr),
         .p4_mcb_cmd_bl                  (c1_p4_cmd_bl),
         .p4_mcb_cmd_addr                (c1_p4_cmd_byte_addr),
         .p4_mcb_cmd_full                (c1_p4_cmd_full),
         // User Port-4 data write interface will be active only when the port is enabled in 
         // the port configuration Config-1 write direction
         .p4_mcb_wr_en                   (c1_p4_wr_en),
         .p4_mcb_wr_mask                 (c1_p4_wr_mask),
         .p4_mcb_wr_data                 (c1_p4_wr_data),
         .p4_mcb_wr_full                 (c1_p4_wr_full),
         .p4_mcb_wr_fifo_counts          (c1_p4_wr_count),
         // User Port-4 data read interface will be active only when the port is enabled in 
         // the port configuration Config-1 read direction
         .p4_mcb_rd_en                   (c1_p4_rd_en),
         .p4_mcb_rd_data                 (c1_p4_rd_data),
         .p4_mcb_rd_empty                (c1_p4_rd_empty),
         .p4_mcb_rd_fifo_counts          (c1_p4_rd_count),

         // User Port-5 command interface will be active only when the port is enabled in 
         // the port configuration Config-1
         .p5_mcb_cmd_en                  (c1_p5_cmd_en),
         .p5_mcb_cmd_instr               (c1_p5_cmd_instr),
         .p5_mcb_cmd_bl                  (c1_p5_cmd_bl),
         .p5_mcb_cmd_addr                (c1_p5_cmd_byte_addr),
         .p5_mcb_cmd_full                (c1_p5_cmd_full),
         // User Port-5 data write interface will be active only when the port is enabled in 
         // the port configuration Config-1 write direction
         .p5_mcb_wr_en                   (c1_p5_wr_en),
         .p5_mcb_wr_mask                 (c1_p5_wr_mask),
         .p5_mcb_wr_data                 (c1_p5_wr_data),
         .p5_mcb_wr_full                 (c1_p5_wr_full),
         .p5_mcb_wr_fifo_counts          (c1_p5_wr_count),
         // User Port-5 data read interface will be active only when the port is enabled in 
         // the port configuration Config-1 read direction
         .p5_mcb_rd_en                   (c1_p5_rd_en),
         .p5_mcb_rd_data                 (c1_p5_rd_data),
         .p5_mcb_rd_empty                (c1_p5_rd_empty),
         .p5_mcb_rd_fifo_counts          (c1_p5_rd_count)
        );
   






endmodule   

 

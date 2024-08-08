//------------------------------------------------------------------------
// memif.v
//
// Memory interface for the XEM7350.
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2009 Opal Kelly Incorporated
// $Rev: 1141 $ $Date: 2012-04-29 18:20:36 -0500 (Sun, 29 Apr 2012) $
//------------------------------------------------------------------------
`timescale 1ns/1ps
// Don't use this because the Xilinx MIG generates code that doesn't declare
// net types on module inputs, so it's not compliant.
//`default_nettype none

module mem_if  #(
      //***************************************************************************
   // The following parameters refer to width of various ports
   //***************************************************************************
	parameter BANK_WIDTH            = 3,
                                     // # of memory Bank Address bits.
	parameter CK_WIDTH              = 1,
                                     // # of CK/CK# outputs to memory.
	parameter COL_WIDTH             = 10,
                                     // # of memory Column Address bits.
	parameter CS_WIDTH              = 1,
                                     // # of unique CS outputs to memory.
	parameter nCS_PER_RANK          = 1,
                                     // # of unique CS outputs per rank for phy
	parameter CKE_WIDTH             = 1,
                                     // # of CKE outputs to memory.
	parameter DATA_BUF_ADDR_WIDTH   = 5,
	parameter DQ_CNT_WIDTH          = 4,
                                     // = ceil(log2(DQ_WIDTH))
	parameter DQ_PER_DM             = 8,
	parameter DM_WIDTH              = 2,
                                     // # of DM (data mask)
	parameter DQ_WIDTH              = 16,
                                     // # of DQ (data)
	parameter DQS_WIDTH             = 2,
	parameter DQS_CNT_WIDTH         = 1,
                                     // = ceil(log2(DQS_WIDTH))
	parameter DRAM_WIDTH            = 8,
                                     // # of DQ per DQS
	parameter ECC                   = "OFF",
	parameter DATA_WIDTH            = 16,
	parameter ECC_TEST              = "OFF",
	parameter PAYLOAD_WIDTH         = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH,
	parameter MEM_ADDR_ORDER        = "BANK_ROW_COLUMN",
                                      //Possible Parameters
                                      //1.BANK_ROW_COLUMN : Address mapping is
                                      //                    in form of Bank Row Column.
                                      //2.ROW_BANK_COLUMN : Address mapping is
                                      //                    in the form of Row Bank Column.
                                      //3.TG_TEST : Scrambles Address bits
                                      //            for distributed Addressing.
      
	parameter nBANK_MACHS           = 4,
	parameter RANKS                 = 1,
                                     // # of Ranks.
	parameter ODT_WIDTH             = 1,
                                     // # of ODT outputs to memory.
	parameter ROW_WIDTH             = 15,
                                     // # of memory Row Address bits.
	parameter ADDR_WIDTH            = 29,
                                     // # = RANK_WIDTH + BANK_WIDTH
                                     //     + ROW_WIDTH + COL_WIDTH;
                                     // Chip Select is always tied to low for
                                     // single rank devices
	parameter USE_CS_PORT          = 1,
                                     // # = 1, When Chip Select (CS#) output is enabled
                                     //   = 0, When Chip Select (CS#) output is disabled
                                     // If CS_N disabled, user must connect
                                     // DRAM CS_N input(s) to ground
	parameter USE_DM_PORT           = 1,
                                     // # = 1, When Data Mask option is enabled
                                     //   = 0, When Data Mask option is disbaled
                                     // When Data Mask option is disabled in
                                     // MIG Controller Options page, the logic
                                     // related to Data Mask should not get
                                     // synthesized
	parameter USE_ODT_PORT          = 1,
                                     // # = 1, When ODT output is enabled
                                     //   = 0, When ODT output is disabled
                                     // Parameter configuration for Dynamic ODT support:
                                     // USE_ODT_PORT = 0, RTT_NOM = "DISABLED", RTT_WR = "60/120".
                                     // This configuration allows to save ODT pin mapping from FPGA.
                                     // The user can tie the ODT input of DRAM to HIGH.
	parameter IS_CLK_SHARED          = "FALSE",
                                      // # = "true" when clock is shared
                                      //   = "false" when clock is not shared 

	parameter PHY_CONTROL_MASTER_BANK = 0,
                                     // The bank index where master PHY_CONTROL resides,
                                     // equal to the PLL residing bank
	parameter MEM_DENSITY           = "4Gb",
                                     // Indicates the density of the Memory part
                                     // Added for the sake of Vivado simulations
	parameter MEM_SPEEDGRADE        = "125",
                                     // Indicates the Speed grade of Memory Part
                                     // Added for the sake of Vivado simulations
	parameter MEM_DEVICE_WIDTH      = 16,
                                     // Indicates the device width of the Memory Part
                                     // Added for the sake of Vivado simulations

   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
	parameter AL                    = "0",
                                     // DDR3 SDRAM:
                                     // Additive Latency (Mode Register 1).
                                     // # = "0", "CL-1", "CL-2".
                                     // DDR2 SDRAM:
                                     // Additive Latency (Extended Mode Register).
	parameter nAL                   = 0,
                                     // # Additive Latency in number of clock
                                     // cycles.
	parameter BURST_MODE            = "8",
                                     // DDR3 SDRAM:
                                     // Burst Length (Mode Register 0).
                                     // # = "8", "4", "OTF".
                                     // DDR2 SDRAM:
                                     // Burst Length (Mode Register).
                                     // # = "8", "4".
	parameter BURST_TYPE            = "SEQ",
                                     // DDR3 SDRAM: Burst Type (Mode Register 0).
                                     // DDR2 SDRAM: Burst Type (Mode Register).
                                     // # = "SEQ" - (Sequential),
                                     //   = "INT" - (Interleaved).
	parameter CL                    = 6,
                                     // in number of clock cycles
                                     // DDR3 SDRAM: CAS Latency (Mode Register 0).
                                     // DDR2 SDRAM: CAS Latency (Mode Register).
	parameter CWL                   = 5,
                                     // in number of clock cycles
                                     // DDR3 SDRAM: CAS Write Latency (Mode Register 2).
                                     // DDR2 SDRAM: Can be ignored
	parameter OUTPUT_DRV            = "LOW",
                                     // Output Driver Impedance Control (Mode Register 1).
                                     // # = "HIGH" - RZQ/7,
                                     //   = "LOW" - RZQ/6.
	parameter RTT_NOM               = "40",
                                     // RTT_NOM (ODT) (Mode Register 1).
                                     //   = "120" - RZQ/2,
                                     //   = "60"  - RZQ/4,
                                     //   = "40"  - RZQ/6.
	 parameter RTT_WR                = "OFF",
                                     // RTT_WR (ODT) (Mode Register 2).
                                     // # = "OFF" - Dynamic ODT off,
                                     //   = "120" - RZQ/2,
                                     //   = "60"  - RZQ/4,
	parameter ADDR_CMD_MODE         = "1T" ,
                                     // # = "1T", "2T".
	parameter REG_CTRL              = "OFF",
                                     // # = "ON" - RDIMMs,
                                     //   = "OFF" - Components, SODIMMs, UDIMMs.
	parameter CA_MIRROR             = "OFF",
                                     // C/A mirror opt for DDR3 dual rank

	parameter VDD_OP_VOLT           = "150",
                                     // # = "150" - 1.5V Vdd Memory part
                                     //   = "135" - 1.35V Vdd Memory part

   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for PLLE2.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
	parameter CLKIN_PERIOD          = 10000,
                                     // Input Clock Period
	parameter CLKFBOUT_MULT         = 8,
                                     // write PLL VCO multiplier
	parameter DIVCLK_DIVIDE         = 1,
                                     // write PLL VCO divisor
	parameter CLKOUT0_PHASE         = 337.5,
                                     // Phase for PLL output clock (CLKOUT0)
	parameter CLKOUT0_DIVIDE        = 2,
                                     // VCO output divisor for PLL output clock (CLKOUT0)
	parameter CLKOUT1_DIVIDE        = 2,
                                     // VCO output divisor for PLL output clock (CLKOUT1)
	parameter CLKOUT2_DIVIDE        = 32,
                                     // VCO output divisor for PLL output clock (CLKOUT2)
	parameter CLKOUT3_DIVIDE        = 8,
                                     // VCO output divisor for PLL output clock (CLKOUT3)

//***************************************************************************
// Memory Timing Parameters. These parameters varies based on the selected
 // memory part.
//***************************************************************************
	parameter tCKE                  = 5000,
                                     // memory tCKE paramter in pS
	parameter tFAW                  = 40000,
                                     // memory tRAW paramter in pS.
	parameter tPRDI                 = 1_000_000,
                                     // memory tPRDI paramter in pS.
	parameter tRAS                  = 35000,
                                     // memory tRAS paramter in pS.
	parameter tRCD                  = 13750,
                                     // memory tRCD paramter in pS.
	parameter tREFI                 = 7800000,
                                     // memory tREFI paramter in pS.
	parameter tRFC                  = 300000,
                                     // memory tRFC paramter in pS.
	parameter tRP                   = 13750,
                                     // memory tRP paramter in pS.
	parameter tRRD                  = 7500,
                                     // memory tRRD paramter in pS.
	parameter tRTP                  = 7500,
                                     // memory tRTP paramter in pS.
	parameter tWTR                  = 7500,
                                     // memory tWTR paramter in pS.
	parameter tZQI                  = 128_000_000,
                                     // memory tZQI paramter in nS.
	parameter tZQCS                 = 64,
                                     // memory tZQCS paramter in clock cycles.

//***************************************************************************
// Simulation parameters
//***************************************************************************
	parameter SIM_BYPASS_INIT_CAL   = "FAST",
                                     // # = "OFF" -  Complete memory init &
                                     //              calibration sequence
                                     // # = "SKIP" - Not supported
                                     // # = "FAST" - Complete memory init & use
                                     //              abbreviated calib sequence

	parameter SIMULATION            = "FALSE",
                                     // Should be TRUE during design simulations and
                                     // FALSE during implementations

//***************************************************************************
// The following parameters varies based on the pin out entered in MIG GUI.
// Do not change any of these parameters directly by editing the RTL.
// Any changes required should be done through GUI and the design regenerated.
//***************************************************************************
	 parameter BYTE_LANES_B0         = 4'b1111,
                                     // Byte lanes used in an IO column.
	parameter BYTE_LANES_B1         = 4'b1000,
                                     // Byte lanes used in an IO column.
	parameter BYTE_LANES_B2         = 4'b0000,
                                     // Byte lanes used in an IO column.
	parameter BYTE_LANES_B3         = 4'b0000,
                                     // Byte lanes used in an IO column.
	parameter BYTE_LANES_B4         = 4'b0000,
                                     // Byte lanes used in an IO column.
	parameter DATA_CTL_B0           = 4'b0001,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
	parameter DATA_CTL_B1           = 4'b1000,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
	parameter DATA_CTL_B2           = 4'b0000,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
	parameter DATA_CTL_B3           = 4'b0000,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
	parameter DATA_CTL_B4           = 4'b0000,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
	parameter PHY_0_BITLANES        = 48'h3FE_FFF_C20_2FF,
	parameter PHY_1_BITLANES        = 48'h3FE_000_000_000,
	parameter PHY_2_BITLANES        = 48'h000_000_000_000,

// control/address/data pin mapping parameters
	parameter CK_BYTE_MAP
     = 144'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_03,
	  parameter ADDR_MAP
     = 192'h000_039_038_037_036_035_034_033_032_031_029_028_027_026_02B_02A,
	parameter BANK_MAP   = 36'h025_024_023,
	parameter CAS_MAP    = 12'h021,
	parameter CKE_ODT_BYTE_MAP = 8'h00,
	parameter CKE_MAP    = 96'h000_000_000_000_000_000_000_01A,
	parameter ODT_MAP    = 96'h000_000_000_000_000_000_000_015,
	parameter CS_MAP     = 120'h000_000_000_000_000_000_000_000_000_01B,
	parameter PARITY_MAP = 12'h000,
	parameter RAS_MAP    = 12'h022,
	parameter WE_MAP     = 12'h020,
	parameter DQS_BYTE_MAP
     = 144'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_13_00,
	parameter DATA0_MAP  = 96'h000_001_002_003_004_005_006_007,
	parameter DATA1_MAP  = 96'h131_132_133_134_135_136_137_138,
	parameter DATA2_MAP  = 96'h000_000_000_000_000_000_000_000,
	parameter DATA3_MAP  = 96'h000_000_000_000_000_000_000_000,
	parameter DATA4_MAP  = 96'h000_000_000_000_000_000_000_000,
	parameter DATA5_MAP  = 96'h000_000_000_000_000_000_000_000,
	parameter DATA6_MAP  = 96'h000_000_000_000_000_000_000_000,
	parameter DATA7_MAP  = 96'h000_000_000_000_000_000_000_000,
	parameter DATA8_MAP  = 96'h000_000_000_000_000_000_000_000,
	parameter DATA9_MAP  = 96'h000_000_000_000_000_000_000_000,
	parameter DATA10_MAP = 96'h000_000_000_000_000_000_000_000,
	parameter DATA11_MAP = 96'h000_000_000_000_000_000_000_000,
	parameter DATA12_MAP = 96'h000_000_000_000_000_000_000_000,
	parameter DATA13_MAP = 96'h000_000_000_000_000_000_000_000,
	parameter DATA14_MAP = 96'h000_000_000_000_000_000_000_000,
	parameter DATA15_MAP = 96'h000_000_000_000_000_000_000_000,
	parameter DATA16_MAP = 96'h000_000_000_000_000_000_000_000,
	parameter DATA17_MAP = 96'h000_000_000_000_000_000_000_000,
	parameter MASK0_MAP  = 108'h000_000_000_000_000_000_000_139_009,
	parameter MASK1_MAP  = 108'h000_000_000_000_000_000_000_000_000,

	parameter SLOT_0_CONFIG         = 8'b0000_0001,
                                     // Mapping of Ranks.
	parameter SLOT_1_CONFIG         = 8'b0000_0000,
                                     // Mapping of Ranks.

//***************************************************************************
// IODELAY and PHY related parameters
//***************************************************************************
	parameter IBUF_LPWR_MODE        = "OFF",
                                     // to phy_top
	parameter DATA_IO_IDLE_PWRDWN   = "ON",
                                     // # = "ON", "OFF"
	parameter BANK_TYPE             = "HP_IO",
                                     // # = "HP_IO", "HPL_IO", "HR_IO", "HRL_IO"
	parameter DATA_IO_PRIM_TYPE     = "HP_LP",
                                     // # = "HP_LP", "HR_LP", "DEFAULT"
	parameter CKE_ODT_AUX           = "FALSE",
	parameter USER_REFRESH          = "OFF",
	parameter WRLVL                 = "ON",
                                     // # = "ON" - DDR3 SDRAM
                                     //   = "OFF" - DDR2 SDRAM.
	parameter ORDERING              = "NORM",
                                     // # = "NORM", "STRICT", "RELAXED".
	parameter CALIB_ROW_ADD         = 16'h0000,
                                     // Calibration row address will be used for
                                     // calibration read and write operations
	parameter CALIB_COL_ADD         = 12'h000,
                                     // Calibration column address will be used for
                                     // calibration read and write operations
	parameter CALIB_BA_ADD          = 3'h0,
                                     // Calibration bank address will be used for
                                     // calibration read and write operations
	parameter TCQ                   = 100,
	parameter IODELAY_GRP           = "DDR3_256_16_IODELAY_MIG",
                                     // It is associated to a set of IODELAYs with
                                     // an IDELAYCTRL that have same IODELAY CONTROLLER
                                     // clock frequency.
	parameter SYSCLK_TYPE           = "DIFFERENTIAL",
                                     // System clock type DIFFERENTIAL, SINGLE_ENDED,
                                     // NO_BUFFER
	parameter REFCLK_TYPE           = "USE_SYSTEM_CLOCK",
                                     // Reference clock type DIFFERENTIAL, SINGLE_ENDED,
                                     // NO_BUFFER, USE_SYSTEM_CLOCK
	parameter SYS_RST_PORT          = "FALSE",
                                     // "TRUE" - if pin is selected for sys_rst
                                     //          and IBUF will be instantiated.
                                     // "FALSE" - if pin is not selected for sys_rst
      
	parameter CMD_PIPE_PLUS1        = "ON",
                                     // add pipeline stage between MC and PHY
	parameter DRAM_TYPE             = "DDR3",
	parameter CAL_WIDTH             = "HALF",
	parameter STARVE_LIMIT          = 2,
                                     // # = 2,3,4.

//***************************************************************************
// Referece clock frequency parameters
//***************************************************************************
	parameter REFCLK_FREQ           = 200.0,
                                     // IODELAYCTRL reference clock frequency
	parameter DIFF_TERM_REFCLK      = "TRUE",
                                     // Differential Termination for idelay
                                     // reference clock input pins
//***************************************************************************
// System clock frequency parameters
//***************************************************************************
	parameter tCK                   = 2500,
                                     // memory tCK paramter.
                                     // # = Clock Period in pS.
	parameter nCK_PER_CLK           = 4,
                                     // # of memory CKs per fabric CLK
	parameter DIFF_TERM_SYSCLK      = "FALSE",
                                     // Differential Termination for System
                                     // clock input pins

   

//***************************************************************************
// Debug parameters
//***************************************************************************
	parameter DEBUG_PORT            = "OFF",
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls.

//***************************************************************************
// Temparature monitor parameter
//***************************************************************************
	parameter TEMP_MON_CONTROL      = "INTERNAL",
                                     // # = "INTERNAL", "EXTERNAL"
      
	parameter RST_ACT_LOW           = 0
                                     // =1 for active low reset,
                                     // =0 for active high.
	)
	(
	// Clocks
	input  wire                                clk,
	input  wire                                rst,
	input  wire                                clk_ref,
	input  wire                                mem_refclk,
	input  wire                                freq_refclk,
	input  wire                                sync_pulse,
	input  wire                                rst_phaser_ref,
	input  wire                                pll_locked,
	output wire                                ref_dll_lock,
	output wire                                calib_done,
	
	// Interfaces
	output wire                                app_rdy,
	input  wire                                app_en,
	input  wire  [2:0]                         app_cmd,
	input  wire  [28:0]                        app_addr,
	
	output wire  [127:0]                       app_rd_data,
	output wire                                app_rd_data_end, 
	output wire                                app_rd_data_valid,
	
	output wire                                app_wdf_rdy,
	input  wire                                app_wdf_wren,
	input  wire  [127:0]                       app_wdf_data,
	input  wire                                app_wdf_end,
	input  wire  [15:0]                        app_wdf_mask,

	
	// DDR Memory
	inout wire [DQ_WIDTH-1:0]                       ddr3_dq,
	inout wire [DQS_WIDTH-1:0]                      ddr3_dqs_n,
	inout wire [DQS_WIDTH-1:0]                      ddr3_dqs_p,
	output wire [ROW_WIDTH-1:0]                     ddr3_addr,
	output wire [BANK_WIDTH-1:0]                    ddr3_ba,
	output wire                                     ddr3_ras_n,
	output wire                                     ddr3_cas_n,
	output wire                                     ddr3_we_n,
	output wire                                     ddr3_reset_n,
	output wire [CK_WIDTH-1:0]                      ddr3_ck_p,
	output wire [CK_WIDTH-1:0]                      ddr3_ck_n,
	output wire [CKE_WIDTH-1:0]                     ddr3_cke,
	output wire [CS_WIDTH*nCS_PER_RANK-1:0]         ddr3_cs_n,
	output wire [DM_WIDTH-1:0]                      ddr3_dm,
	output wire [ODT_WIDTH-1:0]                     ddr3_odt
	);

function integer clogb2 (input integer size);
    begin
      size = size - 1;
      for (clogb2=1; size>1; clogb2=clogb2+1)
        size = size >> 1;
    end
  endfunction // clogb2

  function integer STR_TO_INT;
    input [7:0] in;
    begin
      if(in == "8")
        STR_TO_INT = 8;
      else if(in == "4")
        STR_TO_INT = 4;
      else
        STR_TO_INT = 0;
    end
  endfunction

//From example_top.v
	localparam BURST_LENGTH          = STR_TO_INT(BURST_MODE);

//From ddr3_256_16_mig.v
	localparam BM_CNT_WIDTH = clogb2(nBANK_MACHS);
	localparam RANK_WIDTH = clogb2(RANKS);

	localparam ECC_WIDTH = (ECC == "OFF")?
                           0 : (DATA_WIDTH <= 4)?
                            4 : (DATA_WIDTH <= 10)?
                             5 : (DATA_WIDTH <= 26)?
                              6 : (DATA_WIDTH <= 57)?
                               7 : (DATA_WIDTH <= 120)?
                                8 : (DATA_WIDTH <= 247)?
                                 9 : 10;
	localparam DATA_BUF_OFFSET_WIDTH = 1;
	localparam MC_ERR_ADDR_WIDTH = ((CS_WIDTH == 1) ? 0 : RANK_WIDTH)
                                 + BANK_WIDTH + ROW_WIDTH + COL_WIDTH
                                 + DATA_BUF_OFFSET_WIDTH;

	localparam APP_DATA_WIDTH        = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
	localparam APP_MASK_WIDTH        = APP_DATA_WIDTH / 8;
	localparam TEMP_MON_EN           = (SIMULATION == "FALSE") ? "ON" : "OFF";
                                                 // Enable or disable the temp monitor module
	localparam tTEMPSAMPLE           = 10000000;   // sample every 10 us
	localparam XADC_CLK_PERIOD       = 5000;       // Use 200 MHz IODELAYCTRL clockv
  
// Wire declarations  from ddr3_256_16 Top Level
wire [11:0]                       device_temp;
wire [11:0]                       device_temp_i;
  
	//////////////////////////////////////////////////////////
	// Temperature monitoring logic (From ddr3_256_16 Top Level)
	//////////////////////////////////////////////////////////
	generate
	if (TEMP_MON_EN == "ON") begin: temp_mon_enabled
		mig_7series_v2_0_tempmon # (
		.TCQ              (TCQ),
		.TEMP_MON_CONTROL (TEMP_MON_CONTROL),
		.XADC_CLK_PERIOD  (XADC_CLK_PERIOD),
		.tTEMPSAMPLE      (tTEMPSAMPLE)
		)
		u_mig_7series_v2_0_tempmon
		(
		.clk            (clk),
		.xadc_clk       (clk_ref),
		.rst            (rst),
		.device_temp_i  (device_temp_i),
		.device_temp    (device_temp)
		);
	end else begin: temp_mon_disabled
		assign device_temp = 'b0;
	end
	endgenerate


	//////////////////////////////////////////////////////////
	// MIG Top Level (From ddr3_256_16 Top Level)
	//////////////////////////////////////////////////////////
  mig_7series_v2_0_memc_ui_top_std #
    (
     .TCQ                              (TCQ),
     .ADDR_CMD_MODE                    (ADDR_CMD_MODE),
     .AL                               (AL),
     .PAYLOAD_WIDTH                    (PAYLOAD_WIDTH),
     .BANK_WIDTH                       (BANK_WIDTH),
     .BM_CNT_WIDTH                     (BM_CNT_WIDTH),
     .BURST_MODE                       (BURST_MODE),
     .BURST_TYPE                       (BURST_TYPE),
     .CA_MIRROR                        (CA_MIRROR),
     .DDR3_VDD_OP_VOLT                 (VDD_OP_VOLT),
     .CK_WIDTH                         (CK_WIDTH),
     .COL_WIDTH                        (COL_WIDTH),
     .CMD_PIPE_PLUS1                   (CMD_PIPE_PLUS1),
     .CS_WIDTH                         (CS_WIDTH),
     .nCS_PER_RANK                     (nCS_PER_RANK),
     .CKE_WIDTH                        (CKE_WIDTH),
     .DATA_WIDTH                       (DATA_WIDTH),
     .DATA_BUF_ADDR_WIDTH              (DATA_BUF_ADDR_WIDTH),
     .DM_WIDTH                         (DM_WIDTH),
     .DQ_CNT_WIDTH                     (DQ_CNT_WIDTH),
     .DQ_WIDTH                         (DQ_WIDTH),
     .DQS_CNT_WIDTH                    (DQS_CNT_WIDTH),
     .DQS_WIDTH                        (DQS_WIDTH),
     .DRAM_TYPE                        (DRAM_TYPE),
     .DRAM_WIDTH                       (DRAM_WIDTH),
     .ECC                              (ECC),
     .ECC_WIDTH                        (ECC_WIDTH),
     .ECC_TEST                         (ECC_TEST),
     .MC_ERR_ADDR_WIDTH                (MC_ERR_ADDR_WIDTH),
     .REFCLK_FREQ                      (REFCLK_FREQ),
     .nAL                              (nAL),
     .nBANK_MACHS                      (nBANK_MACHS),
     .CKE_ODT_AUX                      (CKE_ODT_AUX),
     .nCK_PER_CLK                      (nCK_PER_CLK),
     .ORDERING                         (ORDERING),
     .OUTPUT_DRV                       (OUTPUT_DRV),
     .IBUF_LPWR_MODE                   (IBUF_LPWR_MODE),
     .DATA_IO_IDLE_PWRDWN              (DATA_IO_IDLE_PWRDWN),
     .BANK_TYPE                        (BANK_TYPE),
     .DATA_IO_PRIM_TYPE                (DATA_IO_PRIM_TYPE),
     .IODELAY_GRP                      (IODELAY_GRP),
     .REG_CTRL                         (REG_CTRL),
     .RTT_NOM                          (RTT_NOM),
     .RTT_WR                           (RTT_WR),
     .CL                               (CL),
     .CWL                              (CWL),
     .tCK                              (tCK),
     .tCKE                             (tCKE),
     .tFAW                             (tFAW),
     .tPRDI                            (tPRDI),
     .tRAS                             (tRAS),
     .tRCD                             (tRCD),
     .tREFI                            (tREFI),
     .tRFC                             (tRFC),
     .tRP                              (tRP),
     .tRRD                             (tRRD),
     .tRTP                             (tRTP),
     .tWTR                             (tWTR),
     .tZQI                             (tZQI),
     .tZQCS                            (tZQCS),
     .USER_REFRESH                     (USER_REFRESH),
     .TEMP_MON_EN                      (TEMP_MON_EN),
     .WRLVL                            (WRLVL),
     .DEBUG_PORT                       (DEBUG_PORT),
     .CAL_WIDTH                        (CAL_WIDTH),
     .RANK_WIDTH                       (RANK_WIDTH),
     .RANKS                            (RANKS),
     .ODT_WIDTH                        (ODT_WIDTH),
     .ROW_WIDTH                        (ROW_WIDTH),
     .ADDR_WIDTH                       (ADDR_WIDTH),
     .APP_DATA_WIDTH                   (APP_DATA_WIDTH),
     .APP_MASK_WIDTH                   (APP_MASK_WIDTH),
     .SIM_BYPASS_INIT_CAL              (SIM_BYPASS_INIT_CAL),
     .BYTE_LANES_B0                    (BYTE_LANES_B0),
     .BYTE_LANES_B1                    (BYTE_LANES_B1),
     .BYTE_LANES_B2                    (BYTE_LANES_B2),
     .BYTE_LANES_B3                    (BYTE_LANES_B3),
     .BYTE_LANES_B4                    (BYTE_LANES_B4),
     .DATA_CTL_B0                      (DATA_CTL_B0),
     .DATA_CTL_B1                      (DATA_CTL_B1),
     .DATA_CTL_B2                      (DATA_CTL_B2),
     .DATA_CTL_B3                      (DATA_CTL_B3),
     .DATA_CTL_B4                      (DATA_CTL_B4),
     .PHY_0_BITLANES                   (PHY_0_BITLANES),
     .PHY_1_BITLANES                   (PHY_1_BITLANES),
     .PHY_2_BITLANES                   (PHY_2_BITLANES),
     .CK_BYTE_MAP                      (CK_BYTE_MAP),
     .ADDR_MAP                         (ADDR_MAP),
     .BANK_MAP                         (BANK_MAP),
     .CAS_MAP                          (CAS_MAP),
     .CKE_ODT_BYTE_MAP                 (CKE_ODT_BYTE_MAP),
     .CKE_MAP                          (CKE_MAP),
     .ODT_MAP                          (ODT_MAP),
     .CS_MAP                           (CS_MAP),
     .PARITY_MAP                       (PARITY_MAP),
     .RAS_MAP                          (RAS_MAP),
     .WE_MAP                           (WE_MAP),
     .DQS_BYTE_MAP                     (DQS_BYTE_MAP),
     .DATA0_MAP                        (DATA0_MAP),
     .DATA1_MAP                        (DATA1_MAP),
     .DATA2_MAP                        (DATA2_MAP),
     .DATA3_MAP                        (DATA3_MAP),
     .DATA4_MAP                        (DATA4_MAP),
     .DATA5_MAP                        (DATA5_MAP),
     .DATA6_MAP                        (DATA6_MAP),
     .DATA7_MAP                        (DATA7_MAP),
     .DATA8_MAP                        (DATA8_MAP),
     .DATA9_MAP                        (DATA9_MAP),
     .DATA10_MAP                       (DATA10_MAP),
     .DATA11_MAP                       (DATA11_MAP),
     .DATA12_MAP                       (DATA12_MAP),
     .DATA13_MAP                       (DATA13_MAP),
     .DATA14_MAP                       (DATA14_MAP),
     .DATA15_MAP                       (DATA15_MAP),
     .DATA16_MAP                       (DATA16_MAP),
     .DATA17_MAP                       (DATA17_MAP),
     .MASK0_MAP                        (MASK0_MAP),
     .MASK1_MAP                        (MASK1_MAP),
     .CALIB_ROW_ADD                    (CALIB_ROW_ADD),
     .CALIB_COL_ADD                    (CALIB_COL_ADD),
     .CALIB_BA_ADD                     (CALIB_BA_ADD),
     .SLOT_0_CONFIG                    (SLOT_0_CONFIG),
     .SLOT_1_CONFIG                    (SLOT_1_CONFIG),
     .MEM_ADDR_ORDER                   (MEM_ADDR_ORDER),
     .STARVE_LIMIT                     (STARVE_LIMIT),
     .USE_CS_PORT                      (USE_CS_PORT),
     .USE_DM_PORT                      (USE_DM_PORT),
     .USE_ODT_PORT                     (USE_ODT_PORT),
     .MASTER_PHY_CTL                   (PHY_CONTROL_MASTER_BANK)
     )
    u_mig_7series_v2_0_memc_ui_top_std
      (
       .clk                              (clk),
       .clk_ref                          (clk_ref),
       .mem_refclk                       (mem_refclk), //memory clock
       .freq_refclk                      (freq_refclk),
       .pll_lock                         (pll_locked),
       .sync_pulse                       (sync_pulse),
       .rst                              (rst),
       .rst_phaser_ref                   (rst_phaser_ref),
       .ref_dll_lock                     (ref_dll_lock),

	// Memory interface ports
       .ddr_dq                           (ddr3_dq),
       .ddr_dqs_n                        (ddr3_dqs_n),
       .ddr_dqs                          (ddr3_dqs_p),
       .ddr_addr                         (ddr3_addr),
       .ddr_ba                           (ddr3_ba),
       .ddr_cas_n                        (ddr3_cas_n),
       .ddr_ck_n                         (ddr3_ck_n),
       .ddr_ck                           (ddr3_ck_p),
       .ddr_cke                          (ddr3_cke),
       .ddr_cs_n                         (ddr3_cs_n),
       .ddr_dm                           (ddr3_dm),
       .ddr_odt                          (ddr3_odt),
       .ddr_ras_n                        (ddr3_ras_n),
       .ddr_reset_n                      (ddr3_reset_n),
       .ddr_parity                       (),
       .ddr_we_n                         (ddr3_we_n),
       .bank_mach_next                   (),

	// Application interface ports
       .app_addr                         (app_addr),
       .app_cmd                          (app_cmd),
       .app_en                           (app_en),
       .app_hi_pri                       (1'b0),
       .app_wdf_data                     (app_wdf_data),
       .app_wdf_end                      (app_wdf_end),
       .app_wdf_mask                     (app_wdf_mask),
       .app_wdf_wren                     (app_wdf_wren),
       .app_ecc_multiple_err             (),
       .app_rd_data                      (app_rd_data),
       .app_rd_data_end                  (app_rd_data_end),
       .app_rd_data_valid                (app_rd_data_valid),
       .app_rdy                          (app_rdy),
       .app_wdf_rdy                      (app_wdf_rdy),
       
       .app_sr_req                       (1'b0),
       .app_ref_req                      (1'b0),
       .app_zq_req                       (1'b0),
       
       .app_sr_active                    (),
       .app_ref_ack                      (),
       .app_zq_ack                       (),
       .app_raw_not_ecc                  ({2*nCK_PER_CLK{1'b0}}),
       .app_correct_en_i                 (1'b1),

       .device_temp                      (device_temp),
 
       .init_calib_complete              (calib_done)
	);



endmodule

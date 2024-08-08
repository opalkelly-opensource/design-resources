// clocks.v
//
// This is a mash-up of the MIG-generated infrastructure.v file as well as 
// other clock management that is required for the image sensor interface.
//

`timescale 1ns/1ps

module clocks # (
	// MIG Infrastructure Parameters
	parameter SIMULATION      = "FALSE",  // Should be TRUE during design simulations and
                                         // FALSE during implementations
	parameter TCQ             = 100,      // clk->out delay (sim only)
	parameter CLKIN_PERIOD    = 3000,     // Memory clock period
	parameter nCK_PER_CLK     = 2,        // Fabric clk period:Memory clk period
	parameter SYSCLK_TYPE     = "DIFFERENTIAL",
                                         // input clock type
                                         // "DIFFERENTIAL","SINGLE_ENDED"
	parameter UI_EXTRA_CLOCKS = "FALSE",
                                         // Generates extra clocks as
                                         // 1/2, 1/4 and 1/8 of fabrick clock.
                                         // Valid for DDR2/DDR3 AXI interfaces
                                         // based on GUI selection
	parameter CLKFBOUT_MULT   = 4,        // write PLL VCO multiplier
	parameter DIVCLK_DIVIDE   = 1,        // write PLL VCO divisor
	parameter CLKOUT0_PHASE   = 45.0,     // VCO output divisor for clkout0
	parameter CLKOUT0_DIVIDE   = 16,      // VCO output divisor for PLL clkout0
	parameter CLKOUT1_DIVIDE   = 4,       // VCO output divisor for PLL clkout1
	parameter CLKOUT2_DIVIDE   = 64,      // VCO output divisor for PLL clkout2
	parameter CLKOUT3_DIVIDE   = 16,      // VCO output divisor for PLL clkout3
	parameter MMCM_CLKOUT0_EN       = "FALSE",  // Enabled (or) Disable MMCM clkout0
	parameter MMCM_CLKOUT1_EN       = "FALSE",  // Enabled (or) Disable MMCM clkout1
	parameter MMCM_CLKOUT2_EN       = "FALSE",  // Enabled (or) Disable MMCM clkout2
	parameter MMCM_CLKOUT3_EN       = "FALSE",  // Enabled (or) Disable MMCM clkout3
	parameter MMCM_CLKOUT4_EN       = "FALSE",  // Enabled (or) Disable MMCM clkout4
	parameter MMCM_CLKOUT0_DIVIDE   = 1,  // VCO output divisor for MMCM clkout0
	parameter MMCM_CLKOUT1_DIVIDE   = 1,  // VCO output divisor for MMCM clkout1
	parameter MMCM_CLKOUT2_DIVIDE   = 1,  // VCO output divisor for MMCM clkout2
	parameter MMCM_CLKOUT3_DIVIDE   = 1,  // VCO output divisor for MMCM clkout3
	parameter MMCM_CLKOUT4_DIVIDE   = 1,  // VCO output divisor for MMCM clkout4
	parameter RST_ACT_LOW  = 1,

	// Parameters from ddr3_256_16_mig.v
	parameter DIFF_TERM_SYSCLK      = "FALSE",
	parameter IODELAY_GRP           = "DDR3_256_16_IODELAY_MIG",
	parameter REFCLK_TYPE           = "USE_SYSTEM_CLOCK",
	parameter DIFF_TERM_REFCLK      = "TRUE",

	//EVB Parameters
	parameter CLKOUT4_DIVIDE   = 16,            // VCO output divisor for clkout4
	parameter CLKOUT5_DIVIDE   = 16,            // VCO output divisor for clkout5
	parameter C_CLKPIXEXT_DIVIDE      = 31,     // Image sensor EXTCLK divider
	parameter PIXGEN_PHASE_SHIFT      = 0       // Phase shift for PIX_CLK generation
) (
	input  wire        sys_clk,
	input  wire        sys_clk_p,
	input  wire        sys_clk_n,
	input  wire        sys_rst,
	
	// MIG Clocks
	output wire clk,                // Fabric clock freq at half/quarter rate.
	output wire clk_ref,            // IODELAY Reference Clock
	output wire mem_refclk,         // Equal to  memory clock
	output wire freq_refclk,        // Reference Clock
	output wire pll_locked,         // Locked output from PLLE2_ADV
	output wire sync_pulse,         // Exactly 1/16 of mem_refclk and the sync pulse is exactly 1 memref_clk wide
	output wire rstdiv0,            // Reset CLK and CLKDIV logic (incl I/O),
	output wire rst_phaser_ref,
	input  wire ref_dll_lock,
	
	// Sensor Clocks
	output wire        pix_extclk,          // Outgoing image sensor EXTCLK (96 MHz)
	input  wire        pix_clk,             // Incoming pixel clock from the sensor
	input  wire        reset_pixdcm,
	output wire        clk_pix
	);
	
	// MIG
	wire clk_ref_in;
	wire mmcm_clk;             // 200MHz System Clock
	wire iodelay_ctrl_rdy;
	wire pix_extclk_i;
	wire pll_clkfbout, clk_pll_i;
	wire sys_rst_o;
	
	// EVB
	wire                       pix_extclk_bufg_in;
	wire                       clk_pix_bufg_in, clkpix_bufg;
	

	//////////////////////////////////////////////////////////
	// MIG Clock IBUF (From ddr3_256_16 Top Level)
	//////////////////////////////////////////////////////////
	mig_7series_v2_0_clk_ibuf #
	(
		.SYSCLK_TYPE      (SYSCLK_TYPE),
		.DIFF_TERM_SYSCLK (DIFF_TERM_SYSCLK)
	)
	u_ddr3_clk_ibuf (
		.sys_clk_p        (sys_clk_p),
		.sys_clk_n        (sys_clk_n),
		.sys_clk_i        (sys_clk),
		.mmcm_clk         (mmcm_clk) 
	);
	
	//////////////////////////////////////////////////////////
	// MIG IODELAY Control (From ddr3_256_16 Top Level)
	// Modified to inclued pll_locked in reset logic
	//////////////////////////////////////////////////////////
	generate
		if (REFCLK_TYPE == "USE_SYSTEM_CLOCK")
			assign clk_ref_in = mmcm_clk;
	endgenerate

	mig_7series_v2_0_iodelay_ctrl #
	(
		.TCQ              (TCQ),
		.IODELAY_GRP      (IODELAY_GRP),
		.REFCLK_TYPE      (REFCLK_TYPE),
		.SYSCLK_TYPE      (SYSCLK_TYPE),
		.RST_ACT_LOW      (RST_ACT_LOW),
		.DIFF_TERM_REFCLK (DIFF_TERM_REFCLK)
		)
	u_mig_7series_v2_0_iodelay_ctrl(
		// Outputs
		.iodelay_ctrl_rdy (iodelay_ctrl_rdy),
		.sys_rst_o        (sys_rst_o),
		.clk_ref          (clk_ref),
		// Inputs
		.clk_ref_p        (1'b0),
		.clk_ref_n        (1'b0),
		.clk_ref_i        (clk_ref_in),
		.sys_rst          (sys_rst)
	);
	
	
	//////////////////////////////////////////////////////////
	// MIG Infrastructure Internals (From mig_7series_v2_0_infrastructure)
	//////////////////////////////////////////////////////////
	localparam RST_SYNC_NUM = 25;

  // Round up for clk reset delay to ensure that CLKDIV reset deassertion
  // occurs at same time or after CLK reset deassertion (still need to
  // consider route delay - add one or two extra cycles to be sure!)
	 localparam RST_DIV_SYNC_NUM = (RST_SYNC_NUM+1)/2;

  // Input clock is assumed to be equal to the memory clock frequency
  // User should change the parameter as necessary if a different input
  // clock frequency is used
	localparam real CLKIN1_PERIOD_NS = CLKIN_PERIOD / 1000.0;
  //localparam CLKOUT4_DIVIDE = 2 * CLKOUT1_DIVIDE;

	localparam integer VCO_PERIOD
             = (CLKIN1_PERIOD_NS * DIVCLK_DIVIDE * 1000) / CLKFBOUT_MULT;

	localparam CLKOUT0_PERIOD = VCO_PERIOD * CLKOUT0_DIVIDE;
	localparam CLKOUT1_PERIOD = VCO_PERIOD * CLKOUT1_DIVIDE;
	localparam CLKOUT2_PERIOD = VCO_PERIOD * CLKOUT2_DIVIDE;
	localparam CLKOUT3_PERIOD = VCO_PERIOD * CLKOUT3_DIVIDE;
	localparam CLKOUT4_PERIOD = VCO_PERIOD * CLKOUT4_DIVIDE;

	localparam CLKOUT4_PHASE  = (SIMULATION == "TRUE") ? 22.5 : 168.75;

	localparam real CLKOUT3_PERIOD_NS = CLKOUT3_PERIOD / 1000.0;
	localparam real CLKOUT4_PERIOD_NS = CLKOUT4_PERIOD / 1000.0;
	
	  //synthesis translate_off
  initial begin
    $display("############# Write Clocks PLLE2_ADV Parameters #############\n");
    $display("nCK_PER_CLK      = %7d",   nCK_PER_CLK     );
    $display("CLK_PERIOD       = %7d",   CLKIN_PERIOD    );
    $display("CLKIN1_PERIOD    = %7.3f", CLKIN1_PERIOD_NS);
    $display("DIVCLK_DIVIDE    = %7d",   DIVCLK_DIVIDE   );
    $display("CLKFBOUT_MULT    = %7d",   CLKFBOUT_MULT );
    $display("VCO_PERIOD       = %7d",   VCO_PERIOD      );
    $display("CLKOUT0_DIVIDE_F = %7d",   CLKOUT0_DIVIDE  );
    $display("CLKOUT1_DIVIDE   = %7d",   CLKOUT1_DIVIDE  );
    $display("CLKOUT2_DIVIDE   = %7d",   CLKOUT2_DIVIDE  );
    $display("CLKOUT3_DIVIDE   = %7d",   CLKOUT3_DIVIDE  );
    $display("CLKOUT0_PERIOD   = %7d",   CLKOUT0_PERIOD  );
    $display("CLKOUT1_PERIOD   = %7d",   CLKOUT1_PERIOD  );
    $display("CLKOUT2_PERIOD   = %7d",   CLKOUT2_PERIOD  );
    $display("CLKOUT3_PERIOD   = %7d",   CLKOUT3_PERIOD  );
    $display("CLKOUT4_PERIOD   = %7d",   CLKOUT4_PERIOD  );
    $display("############################################################\n");
  end
  //synthesis translate_on

	wire                       clk_bufg;
  wire                       clk_pll;
  wire                       clkfbout_pll;
  wire                       mmcm_clkfbout;
  wire                       pll_locked_i
                             /* synthesis syn_maxfan = 10 */;
  (* max_fanout = 50 *) reg [RST_DIV_SYNC_NUM-2:0] rstdiv0_sync_r;
  wire                       rst_tmp;
  (* max_fanout = 50 *) reg rstdiv0_sync_r1
                             /* synthesis syn_maxfan = 10 */;
  wire                       sys_rst_act_hi;

  wire                       rst_tmp_phaser_ref;
  (* max_fanout = 50 *) reg [RST_DIV_SYNC_NUM-1:0] rst_phaser_ref_sync_r
                             /* synthesis syn_maxfan = 10 */;

  // Instantiation of the MMCM primitive
  wire        clkfbout;
  wire        MMCM_Locked_i;
  
  wire        pll_clk3_out;
  wire        pll_clk3;

  assign sys_rst_act_hi = RST_ACT_LOW ? ~sys_rst_o: sys_rst_o;

  //***************************************************************************
  // Assign global clocks:
  //   2. clk     : Half rate / Quarter rate(used for majority of internal logic)
  //***************************************************************************

  assign clk        = clk_bufg;
  assign pll_locked = pll_locked_i & MMCM_Locked_i;

  //***************************************************************************
  // Global base clock generation and distribution
  //***************************************************************************

  //*****************************************************************
  // NOTES ON CALCULTING PROPER VCO FREQUENCY
  //  1. VCO frequency =
  //     1/((DIVCLK_DIVIDE * CLKIN_PERIOD)/(CLKFBOUT_MULT * nCK_PER_CLK))
  //  2. VCO frequency must be in the range [TBD, TBD]
  //*****************************************************************

  PLLE2_ADV #
    (
     .BANDWIDTH          ("OPTIMIZED"),
     .COMPENSATION       ("INTERNAL"),
     .STARTUP_WAIT       ("FALSE"),
     .CLKOUT0_DIVIDE     (CLKOUT0_DIVIDE),  // 4 freq_ref
     .CLKOUT1_DIVIDE     (CLKOUT1_DIVIDE),  // 4 mem_ref
     .CLKOUT2_DIVIDE     (CLKOUT2_DIVIDE),  // 16 sync
     .CLKOUT3_DIVIDE     (CLKOUT3_DIVIDE),  // 16 sysclk
     .CLKOUT4_DIVIDE     (CLKOUT4_DIVIDE),
     .CLKOUT5_DIVIDE     (CLKOUT5_DIVIDE),
     .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
     .CLKFBOUT_MULT      (CLKFBOUT_MULT),
     .CLKFBOUT_PHASE     (0.000),
     .CLKIN1_PERIOD      (CLKIN1_PERIOD_NS),
     .CLKIN2_PERIOD      (),
     .CLKOUT0_DUTY_CYCLE (0.500),
     .CLKOUT0_PHASE      (CLKOUT0_PHASE),
     .CLKOUT1_DUTY_CYCLE (0.500),
     .CLKOUT1_PHASE      (0.000),
     .CLKOUT2_DUTY_CYCLE (1.0/16.0),
     .CLKOUT2_PHASE      (9.84375),     // PHASE shift is required for sync pulse generation.
     .CLKOUT3_DUTY_CYCLE (0.500),
     .CLKOUT3_PHASE      (0.000),
     .CLKOUT4_DUTY_CYCLE (0.500),
     .CLKOUT4_PHASE      (CLKOUT4_PHASE),
     .CLKOUT5_DUTY_CYCLE (0.500),
     .CLKOUT5_PHASE      (0.000),
     .REF_JITTER1        (0.010),
     .REF_JITTER2        (0.010)
     )
    plle2_i
      (
       .CLKFBOUT (pll_clkfbout),
       .CLKOUT0  (freq_refclk),
       .CLKOUT1  (mem_refclk),
       .CLKOUT2  (sync_pulse),  // always 1/16 of mem_ref_clk
       .CLKOUT3  (pll_clk3_out),
       .CLKOUT4  (pix_extclk_bufg_in),
       .DO       (),
       .DRDY     (),
       .LOCKED   (pll_locked_i),
       .CLKFBIN  (pll_clkfbout),
       .CLKIN1   (mmcm_clk),
       .CLKIN2   (),
       .CLKINSEL (1'b1),
       .DADDR    (7'b0),
       .DCLK     (1'b0),
       .DEN      (1'b0),
       .DI       (16'b0),
       .DWE      (1'b0),
       .PWRDWN   (1'b0),
       .RST      ( sys_rst_act_hi)
       );

	BUFG u_bufg_clkdiv0 (.O (clk_bufg), .I (clk_pll_i) );
	BUFG U_BUFG_CLK4 (.I(pix_extclk_bufg_in),   .O(pix_extclk));
	BUFH u_bufh_pll_clk3(.O (pll_clk3),.I (pll_clk3_out));

	localparam  integer MMCM_VCO_MIN_FREQ     = 600;
	localparam  integer MMCM_VCO_MAX_FREQ     = 1200; // This is the maximum VCO frequency for a -1 part
	localparam  real    MMCM_VCO_MIN_PERIOD   = 1000000.0/MMCM_VCO_MAX_FREQ;
	localparam  real    MMCM_VCO_MAX_PERIOD   = 1000000.0/MMCM_VCO_MIN_FREQ;
	localparam  real    MMCM_MULT_F_MID       = CLKOUT3_PERIOD/(MMCM_VCO_MAX_PERIOD*0.75);
	localparam  real    MMCM_EXPECTED_PERIOD  = CLKOUT3_PERIOD / MMCM_MULT_F_MID;
	localparam  real    MMCM_MULT_F           = ((MMCM_EXPECTED_PERIOD > MMCM_VCO_MAX_PERIOD) ? MMCM_MULT_F_MID + 1.0 : MMCM_MULT_F_MID);
	localparam  real    MMCM_VCO_FREQ         = MMCM_MULT_F / (1 * CLKOUT3_PERIOD_NS);
	localparam  real    MMCM_VCO_PERIOD       = (CLKOUT3_PERIOD_NS * 1000) / MMCM_MULT_F;
  
  //synthesis translate_off
  initial begin
    $display("############# MMCME2_ADV Parameters #############\n");
    $display("MMCM_VCO_MIN_PERIOD   = %7.3f", MMCM_VCO_MIN_PERIOD);
    $display("MMCM_VCO_MAX_PERIOD   = %7.3f", MMCM_VCO_MAX_PERIOD);
    $display("MMCM_MULT_F_MID       = %7.3f", MMCM_MULT_F_MID);
    $display("MMCM_EXPECTED_PERIOD  = %7.3f", MMCM_EXPECTED_PERIOD);
    $display("MMCM_MULT_F           = %7.3f", MMCM_MULT_F);
    $display("CLKOUT3_PERIOD_NS     = %7.3f", CLKOUT3_PERIOD_NS);
    $display("MMCM_VCO_FREQ (MHz)   = %7.3f", MMCM_VCO_FREQ*1000.0);
    $display("MMCM_VCO_PERIOD       = %7.3f", MMCM_VCO_PERIOD);
    $display("#################################################\n");
  end
  //synthesis translate_on
  
       MMCME2_ADV
      #(.BANDWIDTH            ("HIGH"),
        .CLKOUT4_CASCADE      ("FALSE"),
        .COMPENSATION         ("BUF_IN"),
        .STARTUP_WAIT         ("FALSE"),
        .DIVCLK_DIVIDE        (1),
        .CLKFBOUT_MULT_F      (MMCM_MULT_F),
        .CLKFBOUT_PHASE       (0.000),
        .CLKFBOUT_USE_FINE_PS ("FALSE"),
        .CLKOUT0_DIVIDE_F     (MMCM_MULT_F),
        .CLKOUT0_PHASE        (0.000),
        .CLKOUT0_DUTY_CYCLE   (0.500),
        .CLKOUT0_USE_FINE_PS  ("FALSE"),
        .CLKOUT1_DIVIDE       (),
        .CLKOUT1_PHASE        (0.000),
        .CLKOUT1_DUTY_CYCLE   (0.500),
        .CLKOUT1_USE_FINE_PS  ("FALSE"),
        .CLKIN1_PERIOD        (CLKOUT3_PERIOD_NS),
        .REF_JITTER1          (0.000))
      mmcm_i
        // Output clocks
       (.CLKFBOUT            (clk_pll_i),
        .CLKFBOUTB           (),
        .CLKOUT0             (),
        .CLKOUT0B            (),
        .CLKOUT1             (),
        .CLKOUT1B            (),
        .CLKOUT2             (),
        .CLKOUT2B            (),
        .CLKOUT3             (),
        .CLKOUT3B            (),
        .CLKOUT4             (),
        .CLKOUT5             (),
        .CLKOUT6             (),
         // Input clock control
        .CLKFBIN             (clk_bufg),      // From BUFH network
        .CLKIN1              (pll_clk3),      // From PLL
        .CLKIN2              (1'b0),
         // Tied to always select the primary input clock
        .CLKINSEL            (1'b1),
        // Ports for dynamic reconfiguration
        .DADDR               (7'h0),
        .DCLK                (1'b0),
        .DEN                 (1'b0),
        .DI                  (16'h0),
        .DO                  (),
        .DRDY                (),
        .DWE                 (1'b0),
        // Ports for dynamic phase shift
        .PSCLK               (1'b0),
        .PSEN                (1'b0),
        .PSINCDEC            (1'b0),
        .PSDONE              (),
        // Other control and status signals
        .LOCKED              (MMCM_Locked_i),
        .CLKINSTOPPED        (),
        .CLKFBSTOPPED        (),
        .PWRDWN              (1'b0),
        .RST                 (~pll_locked_i));
    
  // RESET SYNCHRONIZATION
  assign rst_tmp = sys_rst_act_hi | ~iodelay_ctrl_rdy |
                   ~ref_dll_lock | ~MMCM_Locked_i;

  always @(posedge clk_bufg or posedge rst_tmp) begin
    if (rst_tmp) begin
      rstdiv0_sync_r  <= #TCQ {RST_DIV_SYNC_NUM-1{1'b1}};
      rstdiv0_sync_r1 <= #TCQ 1'b1 ;
    end else begin
      rstdiv0_sync_r  <= #TCQ rstdiv0_sync_r << 1;
      rstdiv0_sync_r1 <= #TCQ rstdiv0_sync_r[RST_DIV_SYNC_NUM-2];
    end
  end

  assign rstdiv0 = rstdiv0_sync_r1 ;


  assign rst_tmp_phaser_ref = sys_rst_act_hi | ~MMCM_Locked_i | ~iodelay_ctrl_rdy;

  always @(posedge clk_bufg or posedge rst_tmp_phaser_ref)
    if (rst_tmp_phaser_ref)
      rst_phaser_ref_sync_r <= #TCQ {RST_DIV_SYNC_NUM{1'b1}};
    else
      rst_phaser_ref_sync_r <= #TCQ rst_phaser_ref_sync_r << 1;

  assign rst_phaser_ref = rst_phaser_ref_sync_r[RST_DIV_SYNC_NUM-1];
	// *END* MIG Infrastructure Internals ////////////////////////////////



//-------------------------------------------------------------------------
// DCM to capture the PIX_CLK from the image sensor and create a local
// pixel clock to capture incoming pixel data.
//-------------------------------------------------------------------------
DCM_SP # (
		.CLKDV_DIVIDE(2.0),                   // CLKDV divide value
		                                      // (1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,9,10,11,12,13,14,15,16).
		.CLKFX_DIVIDE(1),                     // Divide value on CLKFX outputs - D - (1-32)
		.CLKFX_MULTIPLY(4),                   // Multiply value on CLKFX outputs - M - (2-32)
		.CLKIN_DIVIDE_BY_2("FALSE"),          // CLKIN divide by two (TRUE/FALSE)
		.CLKIN_PERIOD(13.8),                  // Input clock period specified in nS
		.CLKOUT_PHASE_SHIFT("FIXED"),         // Output phase shift (NONE, FIXED, VARIABLE)
		.CLK_FEEDBACK("1X"),                  // Feedback source (NONE, 1X, 2X)
		.DESKEW_ADJUST("SOURCE_SYNCHRONOUS"), // SYSTEM_SYNCHRNOUS or SOURCE_SYNCHRONOUS
		.DFS_FREQUENCY_MODE("LOW"),           // Unsupported - Do not change value
		.DLL_FREQUENCY_MODE("LOW"),           // Unsupported - Do not change value
		.DSS_MODE("NONE"),                    // Unsupported - Do not change value
		.DUTY_CYCLE_CORRECTION("TRUE"),       // Unsupported - Do not change value
		.FACTORY_JF(16'hc080),                // Unsupported - Do not change value
		.PHASE_SHIFT(PIXGEN_PHASE_SHIFT),     // Amount of fixed phase shift (-255 to 255)
		.STARTUP_WAIT("FALSE")                // Delay config DONE until DCM_SP LOCKED (TRUE/FALSE)
	) DCM_SP_inst (
		.CLKIN    (pix_clk),            // 1-bit input: Clock input
		.CLKFB    (clkpix_bufg),        // 1-bit input: Clock feedback input
		.RST      (reset_pixdcm),       // 1-bit input: Active high reset input
		.DSSEN    (1'b0),               // 1-bit input: Unsupported, specify to GND.
		.PSCLK    (),                   // 1-bit input: Phase shift clock input
		.PSEN     (1'b0),               // 1-bit input: Phase shift enable
		.PSINCDEC (),                   // 1-bit input: Phase shift increment/decrement input
	
		.CLK0     (clk_pix_bufg_in),    // 1-bit output: 0 degree clock output
		.CLK180   (),                   // 1-bit output: 180 degree clock output
		.CLK270   (),                   // 1-bit output: 270 degree clock output
		.CLK2X    (),                   // 1-bit output: 2X clock frequency clock output
		.CLK2X180 (),                   // 1-bit output: 2X clock frequency, 180 degree clock output
		.CLK90    (),                   // 1-bit output: 90 degree clock output
		.CLKDV    (),                   // 1-bit output: Divided clock output
		.CLKFX    (),                   // 1-bit output: Digital Frequency Synthesizer output (DFS)
		.CLKFX180 (),                   // 1-bit output: 180 degree CLKFX output
		.LOCKED   (),                   // 1-bit output: DCM_SP Lock Output
		.PSDONE   (),                   // 1-bit output: Phase shift done output
		.STATUS   ()                    // 8-bit output: DCM_SP status output
	);

BUFG U_BUFG_CLKPIX (.I(clk_pix_bufg_in), .O(clkpix_bufg));

// Invert the output of the PIX_CLK DCM.  This means that CLK_PIX is 
// inverted from the image sensor's PIX_CLK.  Therefore, we will 
// capture all inputs on the falling edge of PIX_CLK.
assign clk_pix = ~clkpix_bufg;

endmodule

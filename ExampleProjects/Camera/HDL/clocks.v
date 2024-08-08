// clocks.v
//
// This is a mash-up of the MIG-generated infrastructure.v file as well as 
// other clock management that is required for the image sensor interface.
//

`timescale 1ns/1ps

module clocks # (
		parameter C_RST_ACT_LOW           = 1,
		parameter C_INPUT_CLK_TYPE        = "DIFFERENTIAL",
		parameter C_INCLK_PERIOD          = 10000,     // System clock period (ps)
		parameter C_DIVCLK_DIVIDE         = 5,         // Input clock divider
		parameter C_CLKFBOUT_MULT         = 31,        // PLL multiplier  VCO = (INCLK / DIV) * MULT
		parameter C_CLKDDR0_DIVIDE        = 1,         // DDR divider (0-phase)
		parameter C_CLKDDR1_DIVIDE        = 1,         // DDR divider (180-phase)
		parameter C_CLKSYS_DIVIDE         = 5,         // Logic clock divider
		parameter C_CLKMCB_DIVIDE         = 8,         // MCB clock divider
		parameter C_CLKPIXEXT_DIVIDE      = 31,        // Image sensor EXTCLK divider
		parameter PIXGEN_PHASE_SHIFT      = 0          // Phase shift for PIX_CLK generation
	) (
		input  wire        sys_clk,
		input  wire        sys_clk_p,
		input  wire        sys_clk_n,
		input  wire        sys_rst_n,
		output wire        clk0,
		output wire        rst0,
		output wire        async_rst,
		output wire        sysclk_2x,
		output wire        sysclk_2x_180,
		output wire        pll_ce_0,
		output wire        pll_ce_90,
		output wire        pll_lock,
		output wire        mcb_drp_clk,

		output wire        pix_extclk,          // Outgoing image sensor EXTCLK (96 MHz)
		input  wire        pix_clk,             // Incoming pixel clock from the sensor
		input  wire        reset_pixdcm,
		output wire        clk_pix
	);

// # of clock cycles to delay deassertion of reset. Needs to be a fairly
// high number not so much for metastability protection, but to give time
// for reset (i.e. stable clock cycles) to propagate through all state
// machines and to all control signals (i.e. not all control signals have
// resets, instead they rely on base state logic being reset, and the effect
// of that reset propagating through the logic). Need this because we may not
// be getting stable clock cycles while reset asserted (i.e. since reset
// depends on PLL/DCM lock status)

localparam RST_SYNC_NUM = 25;
localparam CLK_PERIOD_NS = C_INCLK_PERIOD / 1000.0;
localparam CLK_PERIOD_INT = C_INCLK_PERIOD/1000;

wire                       clk_2x_0;
wire                       clk_2x_180;
wire                       clk0_bufg;
wire                       clk0_bufg_in;
wire                       mcb_drp_clk_bufg_in;
wire                       pix_extclk_bufg_in;
wire                       clkfbout_clkfbin;
wire                       clk_pix_bufg_in, clkpix_bufg;
wire                       locked;
reg [RST_SYNC_NUM-1:0]     rst0_sync_r    /* synthesis syn_maxfan = 10 */;
wire                       rst_tmp;
reg                        powerup_pll_locked;
reg                        syn_clk0_powerup_pll_locked;

wire                       sys_rst;
wire                       bufpll_mcb_locked;
(* KEEP = "TRUE" *) wire sys_clk_ibufg;

assign sys_rst = C_RST_ACT_LOW ? ~sys_rst_n: sys_rst_n;
assign clk0        = clk0_bufg;
assign pll_lock    = bufpll_mcb_locked;

generate
	if (C_INPUT_CLK_TYPE == "DIFFERENTIAL") begin: diff_input_clk
		IBUFGDS # ( .DIFF_TERM("TRUE") )
		        u_ibufg_sys_clk (.I(sys_clk_p), .IB(sys_clk_n), .O(sys_clk_ibufg));
	end else if (C_INPUT_CLK_TYPE == "SINGLE_ENDED") begin: se_input_clk
		IBUFG   u_ibufg_sys_clk (.I(sys_clk), .O(sys_clk_ibufg));
	end
endgenerate

//***************************************************************************
// Global clock generation and distribution
//***************************************************************************
PLL_ADV # (
		.BANDWIDTH          ("OPTIMIZED"),
		.CLKIN1_PERIOD      (CLK_PERIOD_NS),
		.CLKIN2_PERIOD      (CLK_PERIOD_NS),
		.CLKOUT0_DIVIDE     (C_CLKDDR0_DIVIDE),
		.CLKOUT1_DIVIDE     (C_CLKDDR1_DIVIDE),
		.CLKOUT2_DIVIDE     (C_CLKSYS_DIVIDE),
		.CLKOUT3_DIVIDE     (C_CLKMCB_DIVIDE),
		.CLKOUT4_DIVIDE     (C_CLKPIXEXT_DIVIDE),
		.CLKOUT5_DIVIDE     (1),
		.CLKOUT0_PHASE      (0.000),
		.CLKOUT1_PHASE      (180.000),
		.CLKOUT2_PHASE      (0.000),
		.CLKOUT3_PHASE      (0.000),
		.CLKOUT4_PHASE      (0.000),
		.CLKOUT5_PHASE      (0.000),
		.CLKOUT0_DUTY_CYCLE (0.500),
		.CLKOUT1_DUTY_CYCLE (0.500),
		.CLKOUT2_DUTY_CYCLE (0.500),
		.CLKOUT3_DUTY_CYCLE (0.500),
		.CLKOUT4_DUTY_CYCLE (0.500),
		.CLKOUT5_DUTY_CYCLE (0.500),
		.SIM_DEVICE         ("SPARTAN6"),
		.COMPENSATION       ("INTERNAL"),
		.DIVCLK_DIVIDE      (C_DIVCLK_DIVIDE),
		.CLKFBOUT_MULT      (C_CLKFBOUT_MULT),
		.CLKFBOUT_PHASE     (0.0),
		.REF_JITTER         (0.005000)
	) u_pll_adv (
		.CLKFBIN     (clkfbout_clkfbin),
		.CLKINSEL    (1'b1),
		.CLKIN1      (sys_clk_ibufg),
		.CLKIN2      (1'b0),
		.DADDR       (5'b0),
		.DCLK        (1'b0),
		.DEN         (1'b0),
		.DI          (16'b0),
		.DWE         (1'b0),
		.REL         (1'b0),
		.RST         (sys_rst),
		.CLKFBDCM    (),
		.CLKFBOUT    (clkfbout_clkfbin),
		.CLKOUTDCM0  (),
		.CLKOUTDCM1  (),
		.CLKOUTDCM2  (),
		.CLKOUTDCM3  (),
		.CLKOUTDCM4  (),
		.CLKOUTDCM5  (),
		.CLKOUT0     (clk_2x_0),
		.CLKOUT1     (clk_2x_180),
		.CLKOUT2     (clk0_bufg_in),
		.CLKOUT3     (mcb_drp_clk_bufg_in),
		.CLKOUT4     (pix_extclk_bufg_in),
		.CLKOUT5     (),
		.DO          (),
		.DRDY        (),
		.LOCKED      (locked)
	);

BUFG U_BUFG_CLK0 (.I(clk0_bufg_in),         .O(clk0_bufg));
BUFG U_BUFG_CLK1 (.I(mcb_drp_clk_bufg_in),  .O(mcb_drp_clk));
BUFG U_BUFG_CLK4 (.I(pix_extclk_bufg_in),   .O(pix_extclk));

always @(posedge mcb_drp_clk, posedge sys_rst) begin
	if (sys_rst)
		powerup_pll_locked <= 1'b0;
	else if (bufpll_mcb_locked)
		powerup_pll_locked <= 1'b1;
end

always @(posedge clk0_bufg, posedge sys_rst) begin
	if(sys_rst)
		syn_clk0_powerup_pll_locked <= 1'b0;
	else if (bufpll_mcb_locked)
		syn_clk0_powerup_pll_locked <= 1'b1;
end

//***************************************************************************
// Reset synchronization
// NOTES:
//   1. shut down the whole operation if the PLL hasn't yet locked (and
//      by inference, this means that external SYS_RST_IN has been asserted -
//      PLL deasserts LOCKED as soon as SYS_RST_IN asserted)
//   2. asynchronously assert reset. This was we can assert reset even if
//      there is no clock (needed for things like 3-stating output buffers).
//      reset deassertion is synchronous.
//   3. asynchronous reset only look at pll_lock from PLL during power up. After
//      power up and pll_lock is asserted, the powerup_pll_locked will be asserted
//      forever until sys_rst is asserted again. PLL will lose lock when FPGA 
//      enters suspend mode. We don't want reset to MCB get
//      asserted in the application that needs suspend feature.
//***************************************************************************

assign async_rst = sys_rst | ~powerup_pll_locked;
assign rst_tmp   = sys_rst | ~syn_clk0_powerup_pll_locked;
assign rst0      = rst0_sync_r[RST_SYNC_NUM-1];
// synthesis attribute max_fanout of rst0_sync_r is 10

always @(posedge clk0_bufg or posedge rst_tmp) begin
	if (rst_tmp)
		rst0_sync_r <= {RST_SYNC_NUM{1'b1}};
	else
		// logical left shift by one (pads with 0)
		rst0_sync_r <= rst0_sync_r << 1;
end


BUFPLL_MCB BUFPLL_MCB1 (
	.IOCLK0         (sysclk_2x),
	.IOCLK1         (sysclk_2x_180),
	.LOCKED         (locked),
	.GCLK           (mcb_drp_clk),
	.SERDESSTROBE0  (pll_ce_0), 
	.SERDESSTROBE1  (pll_ce_90), 
	.PLLIN0         (clk_2x_0),  
	.PLLIN1         (clk_2x_180),
	.LOCK           (bufpll_mcb_locked) 
	);



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

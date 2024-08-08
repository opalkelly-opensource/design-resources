// clocks.v
//
// This module handles the clock management that is required for the image
// sensor interface.
//

`timescale 1ns/1ps
`default_nettype none

module clocks (
	input  wire        pix_clk,             // Incoming pixel clock from the sensor
	input  wire        reset_pixdcm,
	output wire        pll_locked,
	output wire        clk_pix,
    
    // Clock out ports
    output wire        mig_clk,
    output wire        pix_ext_clk,
    // Status and control signals
    input  wire        mig_pix_clkgen_reset,
    output wire        mig_pix_clkgen_locked,
    // Clock in ports
    input  wire        sys_clk_p,
    input  wire        sys_clk_n
	);
	
	wire pix_mmcm_clkfb, pix_mmcm_clkfb_bufg;
	wire clk_pix_bufg_in, clkpix_bufg;

//-------------------------------------------------------------------------
// DCM to capture the PIX_CLK from the image sensor and create a local
// pixel clock to capture incoming pixel data.
//-------------------------------------------------------------------------

MMCME2_BASE # (
	.BANDWIDTH("OPTIMIZED"),
	.CLKFBOUT_MULT_F(10),
	.CLKFBOUT_PHASE(0.0),
	.CLKIN1_PERIOD(13.8),
	.CLKOUT0_DIVIDE_F(10),
	.CLKOUT0_PHASE(270), // 58.5
	.DIVCLK_DIVIDE(1),
	.REF_JITTER1(0.0),
	.STARTUP_WAIT("FALSE")
	) pix_mmcm0 (
	.CLKFBOUT(pix_mmcm_clkfb),
	.CLKOUT0B(),
	.CLKOUT0(clk_pix_bufg_in),
	.LOCKED(pll_locked),
	.CLKIN1(pix_clk),
	.RST(reset_pixdcm),
	.CLKFBIN(pix_mmcm_clkfb_bufg)
);

BUFG mmcm_fb_bufg (.I(pix_mmcm_clkfb), .O(pix_mmcm_clkfb_bufg));
BUFG U_BUFG_CLKPIX (.I(clk_pix_bufg_in), .O(clkpix_bufg));

// Invert the output of the PIX_CLK DCM.  This means that CLK_PIX is 
// inverted from the image sensor's PIX_CLK.  Therefore, we will 
// capture all inputs on the falling edge of PIX_CLK.
//assign clk_pix = ~clkpix_bufg;
assign clk_pix = clkpix_bufg;


mig_pix_clkgen mig_pix_clkgen_i(
  // Clock out ports
  .clk_out1(mig_clk),
  .clk_out2(pix_ext_clk),
  // Status and control signals
  .reset(mig_pix_clkgen_reset),
  .locked(mig_pix_clkgen_locked),
 // Clock in ports
  .clk_in1_p(sys_clk_p),
  .clk_in1_n(sys_clk_n)
 );
endmodule
`default_nettype wire

// clocks.v
//
// This is a mash-up of the MIG-generated infrastructure.v file as well as 
// other clock management that is required for the image sensor interface.
//

`timescale 1ns/1ps

module clocks (
		input  wire        clk,
		input  wire        reset,
		output wire        ext_pll_lock,
		output wire        pix_extclk,          // Outgoing image sensor EXTCLK
		
		input  wire        pix_clk,             // Incoming pixel clock from the sensor
		input  wire        reset_pixpll,
		output wire        pix_pll_lock,
		output wire        clk_pix
	);

//-------------------------------------------------------------------------
// PLL to generate ext_clock for image sensor from memory interface clk 
//
// Input: Clock from Half Rate Memory Interface (66.5Mhz)
// Output: extclk input to image sensor (20MHz)
//-------------------------------------------------------------------------
extclk_pll extclkpll0 (
	.areset (reset),
	.inclk0 (clk),
	.c0 (pix_extclk),
	.locked (ext_pll_lock)
	);

//-------------------------------------------------------------------------
// PLL to capture the PIX_CLK from the image sensor and create a local
// pixel clock to capture incoming pixel data.
// Invert the output of the PIX_CLK PLL.  This means that CLK_PIX is 
// inverted from the image sensor's PIX_CLK.  Therefore, we will 
// capture all inputs on the falling edge of PIX_CLK.
//
// Input: Pixel clock from image sensor (13.8ns -> 72.46MHz)
// Output: Local pixel clock with 180deg phase shift for capturing pixel data
//-------------------------------------------------------------------------
pixclk_pll pixclkpll0 (
	.areset (reset_pixpll),
	.inclk0 (pix_clk),
	.c0 (clk_pix),
	.locked (pix_pll_lock)
	);

endmodule

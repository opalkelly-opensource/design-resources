//------------------------------------------------------------------------
// syzygy-dac-top.v
//
// This is the top level module for the SYZYGY DAC Pod sample. This module
// contains the DAC DDS, PHY, data controller, and SPI controller.
// 
//------------------------------------------------------------------------
// Copyright (c) 2023 Opal Kelly Incorporated
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//------------------------------------------------------------------------

`default_nettype none

module syzygy_dac_top(
	input  wire        clk,
	input  wire        reset,
    
    input  wire [7:0]  ifft_addr,
    
    input  wire [11:0] dac_data_i,
	input  wire        dis_out,  // Disable Output
	input  wire        ifft_ce, // BRAM wr_en

	// SZG-DAC Connections
	output wire [11:0] dac_data_o,
	output wire        dac_clk,
	output wire        dac_reset_pinmd,
	output wire        dac_sclk, // SPI clock
	inout  wire        dac_sdio, // SPI data I/O
	output wire        dac_cs_n,  // SPI Chip Select
	
	output wire        dac_ready
);


// SPI
wire [5:0]  spi_reg;
wire [7:0]  spi_data_in, spi_data_out;
wire        spi_send, spi_done, spi_rw;
wire [11:0] dac_data_bram;
wire        dac_ready;
wire dac_clk_locked;

syzygy_dac_data_reg dac_data_reg(
    .clk      (clk),
    .reset    (reset),
    
    .wr_addr  (ifft_addr),
    .wr_en    (ifft_ce),
    .data_en  (~dis_out),
    .data_i   (dac_data_i),
    .data_o   (dac_data_bram)
);

syzygy_dac_phy dac_phy_impl(
	.clk      (clk),
	.reset    (reset),

	.data_i   (dac_data_bram),
	.data_q   (dac_data_bram), // Output the same data on both channels

	.dac_data (dac_data_o),
	.dac_clk  (dac_clk)
);

syzygy_dac_spi dac_spi(
	.clk          (clk),
	.reset        (reset),

	.dac_sclk     (dac_sclk),     // DAC SPI clk
	.dac_sdio     (dac_sdio),     // DAC SPI SDIO Pin
	.dac_cs_n     (dac_cs_n),     // DAC Chip Select (active low)
	.dac_reset    (dac_reset_pinmd), // DAC Reset Pin

	.spi_reg      (spi_reg),      // DAC SPI register address
	.spi_data_in  (spi_data_in),  // Data to DAC
	.spi_data_out (spi_data_out), // Data from DAC (unused here)
	.spi_send     (spi_send),     // Send command
	.spi_done     (spi_done),     // Command is complete, data_out valid
	.spi_rw       (spi_rw)        // Read or write
);

syzygy_dac_controller dac_control(
	.clk         (clk),
	.reset       (reset),

	.dac_fsadj   (16'h2020),

	.spi_reg     (spi_reg),
	.spi_data_in (spi_data_in),
	.spi_send    (spi_send),
	.spi_done    (spi_done),
	.spi_rw      (spi_rw),

	.dac_ready   (dac_ready)
);

endmodule
`default_nettype wire

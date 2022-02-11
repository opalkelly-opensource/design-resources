//------------------------------------------------------------------------
// syzygy-dac-top.v
//
// This is the top level module for the SYZYGY DAC Pod sample. This module
// contains the DAC DDS, PHY, and controller.
// 
//------------------------------------------------------------------------
// Copyright (c) 2018 Opal Kelly Incorporated
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

	input  wire        dis_out,  // Disable Output
	input  wire        dis_am,   // Disable AM
	input  wire        dis_fm,   // Disable FM

	// Settings
	input  wire [31:0] freq,
	input  wire [15:0] freq_dev, // FM Frequency Deviation
	input  wire [11:0] ampl,
	input  wire [7:0]  depth,

	// SZG-DAC Connections
	output wire [11:0] dac_data, // I data
	output wire        dac_clk,
	output wire        dac_reset_pinmd,
	output wire        dac_sclk, // SPI clock
	inout  wire        dac_sdio, // SPI data I/O
	output wire        dac_cs_n  // SPI Chip Select
);

// DAC //
// SPI
wire [5:0]  spi_reg;
wire [7:0]  spi_data_in, spi_data_out;
wire        spi_send, spi_done, spi_rw;

// Datapath
wire [27:0] inc_delta;
wire [11:0] dac_data_i, dds_out;

wire        dac_ready;

syzygy_dds_fp dds_i(
	.clk       (clk),
	.reset     (reset),

	.dis_out   (dis_out),

	.freq      (freq),
	.phase     (32'd0),
	.inc_delta (inc_delta),

	.data      (dds_out)
);

syzygy_dac_am am_mod(
	.clk      (clk),
	.reset    (reset),

	.dis_mod  (dis_am),
	.dis_out  (dis_out),

	.dds_out  (dds_out),
	.ampl     (ampl),
	.depth    (depth),

	.data     (dac_data_i)
);

syzygy_dac_fm fm_mod(
	.clk       (clk),
	.reset     (reset),

	.dis       (dis_fm),

	.freq_dev  (freq_dev),
	.audio     (ampl),

	.inc_delta (inc_delta)
);

syzygy_dac_phy dac_phy_impl(
	.clk      (clk),
	.reset    (reset),

	.data_i   (dac_data_i),
	.data_q   (dac_data_i), // Output the same data on both channels

	.dac_data (dac_data),
	.dac_clk  (dac_clk)
);

syzygy_dac_spi dac_spi(
	.clk          (clk),
	.reset        (reset),

	.dac_sclk     (dac_sclk),
	.dac_sdio     (dac_sdio),
	.dac_cs_n     (dac_cs_n),
	.dac_reset    (dac_reset_pinmd),

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

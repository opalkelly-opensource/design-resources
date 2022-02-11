//------------------------------------------------------------------------
// syzygy-i2s2-pmod-top.v
//
// Top level module for the PMOD-I2S2 PHY from Digilent. Outputs mono audio
// data.
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

module szg_i2s2_pmod_top(
	input  wire        clk,
	input  wire        reset,

	// FrontPanel
	input  wire        volume,

	// PHY
	output wire        rx_mclk,
	output wire        rx_lrck,
	output wire        rx_sclk,
	input  wire        rx_sdin,

	output reg  [23:0] data
);

// I2S2 PHY
wire [23:0] r_channel, l_channel;
szg_i2s2_pmod_phy szg_i2s2_phy(
	.clk       (clk),
	.reset     (reset),
	.mclk      (rx_mclk),
	.lrck      (rx_lrck),
	.sclk      (rx_sclk),
	.sdin      (rx_sdin),
	
	.r_channel (r_channel),
	.l_channel (l_channel)
);

always @(posedge clk)
	data <= (r_channel + l_channel) / 2;

endmodule

`default_nettype wire

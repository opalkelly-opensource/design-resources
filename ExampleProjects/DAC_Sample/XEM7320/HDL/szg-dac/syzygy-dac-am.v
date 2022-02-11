//------------------------------------------------------------------------
// syzygy-dac-am.v
//
// Amplitude modulation module for use with the SYZYGY DAC sample. Allows
// control of the AM depth.
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

module syzygy_dac_am(
	input  wire        clk,
	input  wire        reset,

	input  wire        dis_mod,
	input  wire        dis_out,

	input  wire [11:0] dds_out,
	input  wire [11:0] ampl,
	input  wire [7:0]  depth,

	output reg  [11:0] data
);

reg [23:0]  mult_out_r, mult_out_r2;
reg [19:0]  div_out_r, div_out_r2;
reg [11:0]  ampl_r;
reg [7:0]   min_ampl_r, depth_r;

wire [19:0] min_ampl_padded;

assign min_ampl_padded = {min_ampl_r, 12'd0};

always @(posedge clk) begin
	if (reset) begin
		ampl_r      <= 12'd0;
		min_ampl_r  <= 12'd0;
		depth_r     <= 12'd0;

		mult_out_r  <= 24'd0;
		mult_out_r2 <= 24'd0;

		div_out_r   <= 20'd0;
		div_out_r2  <= 20'd0;

		data        <= 12'd0;
	end else if (dis_mod)
		// Modulation disabled
		data        <= dds_out;
	else if (dis_out)
		// Output disabled
		data        <= 12'd0;
	else begin
		// Update registers
		ampl_r      <= ampl;
		min_ampl_r  <= 13'd256 - depth;
		depth_r     <= depth;

		div_out_r   <= ampl_r * depth_r;
		// 2nd register for DSP pipelining
		div_out_r2  <= div_out_r + min_ampl_padded;

		mult_out_r  <= div_out_r2[19:8] * dds_out;
		// 2nd register for DSP pipelining
		mult_out_r2 <= mult_out_r;

		data        <= mult_out_r2[23:12];
	end
end

endmodule

`default_nettype wire

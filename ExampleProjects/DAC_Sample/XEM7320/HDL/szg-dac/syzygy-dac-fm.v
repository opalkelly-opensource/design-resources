//------------------------------------------------------------------------
// syzygy-dac-fm.v
//
// Frequency modulation module for use with the SYZYGY DAC sample. Allows
// control of the FM Deviation.
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

module syzygy_dac_fm(
	input  wire        clk,
	input  wire        reset,

	input  wire        dis,

	input  wire [15:0] freq_dev,
	input  wire [11:0] audio,

	output reg  [27:0] inc_delta
);

reg signed [27:0] inc_delta_r;
reg signed [15:0] freq_dev_r;
reg signed [11:0] audio_r;

localparam        down_shift   = 12'h7FF;
localparam        shift_factor = 1'd1;

always @(posedge clk) begin
	if (reset) begin
		inc_delta   <= 28'd0;
		inc_delta_r <= 28'd0;
		freq_dev_r  <= 16'd0;
		audio_r     <= 12'd0;
	end else if (dis)
		// Output disabled
		inc_delta   <= 28'd0;
	else begin
		// Update buffers
		freq_dev_r  <= freq_dev >> shift_factor;
		audio_r     <= audio - down_shift;
		
		inc_delta_r <= freq_dev_r * audio_r;
		inc_delta   <= inc_delta_r; // 2nd register for DSP pipelining
	end
end

endmodule

`default_nettype wire

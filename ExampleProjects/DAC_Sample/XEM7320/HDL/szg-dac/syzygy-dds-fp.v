//------------------------------------------------------------------------
// syzygy-dds-fp.v
//
// Simple synthesizer that uses the Xilinx CORDIC core to generate a
// sine wave, covering all values on the 12-bit data bus.
// Interfaces with FrontPanel.
// Aims to provide single Hz frequency resolution.
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

module syzygy_dds_fp(
	input  wire        clk,
	input  wire        reset,

	input  wire        dis_out,

	input  wire [31:0] freq,
	input  wire [31:0] phase,
	input  wire [27:0] inc_delta,

	output reg  [11:0] data
);

// CORDIC
reg  [69:0]    delta;
reg  [31:0]    counter;
reg  [31:0]    freq_r, phase_r;
reg  [11:0]    cordic_out_shifted_up;

wire [31:0]    inc_delta_signed;
wire [11:0]    cordic_out;
wire           data_valid;

assign inc_delta_signed         = (inc_delta[27]) ? {4'hF, inc_delta} : {4'h0, inc_delta};

// Max value for CORDIC input, 1 (3 FPN)
localparam     max_val          = 32'h40000000;
// Value to subtract counter by before passing into CORDIC
localparam     sub_val          = 32'hE0000000;
// Left bitshift quantity.
localparam     shift_factor     = 6'd37;

// CORDIC Module
cordic_0 cordic_0_inst(
	.aclk                (clk),
	.s_axis_phase_tdata  (counter + phase_r + sub_val), // Input stream, 32-bit width
	.s_axis_phase_tvalid (1'b1),                        // Input validity (always valid)
	.m_axis_dout_tdata   (cordic_out),                  // Output stream, 32-bits, 12-bit width
	.m_axis_dout_tvalid  (data_valid)                   // Output validity
);

always @(posedge clk) begin
	if (reset) begin
		delta                 <= 70'd0;
		delta                <= 70'd0;

		counter               <= 32'd0;

		freq_r                <= 32'd0;
		phase_r               <= 32'd0;

		cordic_out_shifted_up <= 12'd0;
	end else if (dis_out)
		data                  <= 12'd0;
	else begin
		// Update buffers
		freq_r                <= freq + inc_delta_signed;
		phase_r               <= phase;
		delta                 <= freq_r << shift_factor;

		data                  <= cordic_out_shifted_up;

		counter               <= counter + delta[65:34];

		if (counter >= max_val - delta[65:34])
			counter <= counter - max_val + delta[65:34];

		// Shift output up by 1 (2 FPN) from CORDIC to DAC
		cordic_out_shifted_up <= cordic_out + 12'h400;
	end
end

endmodule

`default_nettype wire

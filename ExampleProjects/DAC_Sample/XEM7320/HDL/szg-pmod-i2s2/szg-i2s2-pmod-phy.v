//------------------------------------------------------------------------
// syzygy-i2s2-pmod-phy.v
//
// Physical interface for the PMOD-I2S2 module from Digilent. Implements
// an I2S master for the PMOD-I2S2 ADC.
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

module szg_i2s2_pmod_phy(
	input  wire        clk, // 100.8MHz
	input  wire        reset,

	output wire        mclk,
	output wire        lrck,
	output wire        sclk,
	input  wire        sdin,

	output reg  [23:0] r_channel,
	output reg  [23:0] l_channel
);

reg [23:0] r_channel_r, l_channel_r;
reg [6:0]  valid_count;
reg [10:0] count;
reg        sclk_r, lrck_r;

// Every 4 clk
assign     mclk     = count[1];
// Every 8 * 4 clk
assign     sclk     = count[4];
// Every 8  * 64 clk
assign     lrck     = count[10];

// Upward shift constant
localparam up_shift = 24'h7FFFFF;

always @(posedge clk) begin
	if (reset) begin
		r_channel   <= 24'd0;
		l_channel   <= 24'd0;
		r_channel_r <= 24'd0;
		l_channel_r <= 24'd0;
		valid_count <= 7'd0;
		count       <= 11'd0;
		sclk_r      <= 1'b0;
		lrck_r      <= 1'b0;
	end else begin
		// Clock generation
		count       <= count + 1;

		// Reset left/right count
		if (lrck != lrck_r) valid_count <= 32'd0;

			// Rising edge
			if (sclk && ~sclk_r) begin
				valid_count <= valid_count + 1;
				if (valid_count >= 1 && valid_count <= 24) begin
					// Update respective shift registers
					if (lrck) begin
						r_channel_r <= {r_channel_r[22:0], sdin};
						// Shift upwards for DAC
						l_channel   <= l_channel_r + up_shift;
					end else begin
						l_channel_r <= {l_channel_r[22:0], sdin};
						// Shift upwards for DAC
						r_channel   <= r_channel_r + up_shift;
					end
				end
			end
		// Update last states
		sclk_r      <= sclk;
		lrck_r      <= lrck;
	end
end

endmodule

`default_nettype wire

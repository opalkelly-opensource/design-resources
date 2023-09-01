//------------------------------------------------------------------------
// syzygy-adc-enc.v
//
// This module provides the encode signal to the ADC from a clock input.
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

module syzygy_adc_enc (
	input  wire clk,

	output wire adc_encode_p,
	output wire adc_encode_n
	);

wire adc_encode_int;
	
ODDR #(
	.DDR_CLK_EDGE("OPPOSITE_EDGE"),
	.INIT (1'b0),
	.SRTYPE("SYNC")
) adc_enc_oddr (
	.Q  (adc_encode_int),
	.C  (clk),
	.CE (1'b1),
	.D1 (1'b1),
	.D2 (1'b0),
	.R  (1'b0),
	.S  (1'b0)
);

OBUFDS adc_enc_obuf (
	.I  (adc_encode_int),
	.O  (adc_encode_p),
	.OB (adc_encode_n)
);

endmodule
`default_nettype wire



//------------------------------------------------------------------------
// syzygy-adc-dco.v
//
// This module handles the data clock output from the ADC and provides the
// necessary signals required by the ISERDES input buffers.
// 
//------------------------------------------------------------------------
// Copyright (c) 2017 Opal Kelly Incorporated
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

module syzygy_adc_dco (
	input  wire  reset,

	input  wire  adc_dco_p,      // ADC Data clock
	input  wire  adc_dco_n,

	output wire  clk_out_bufio,
	output wire  clk_out_div     // 1/4 clock rate for data from SERDES
	);

wire clk_out_int; // internal clock net

IBUFDS #(
	.IOSTANDARD ("LVDS_25"),
	.DIFF_TERM  ("TRUE")
) adc_dco_ibufds (
	.I  (adc_dco_p),
	.IB (adc_dco_n),
	.O  (clk_out_int)
);

BUFIO adc_dco_bufio (
	.I (clk_out_int),
	.O (clk_out_bufio)
);

BUFR #(
	.SIM_DEVICE("7SERIES"),
	.BUFR_DIVIDE("4")
) adc_dco_bufr (
	.O   (clk_out_div),
	.CE  (1'b1),
	.CLR (reset),
	.I   (clk_out_int)
);

endmodule
`default_nettype wire



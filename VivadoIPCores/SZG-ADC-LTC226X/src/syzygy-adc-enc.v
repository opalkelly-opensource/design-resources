`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-adc-enc.v
//
// Forwards the sample/encode clock to the ADC through an ODDRE1 (D1=1, D2=0)
// into an LVDS OBUFDS. The ODDR path has less jitter than fabric routing, and
// encode-clock jitter feeds directly into ADC SNR.
//
//------------------------------------------------------------------------
// Copyright (c) 2021-2026 Opal Kelly Incorporated
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

wire clk_fwd;

ODDRE1 #(
    .IS_C_INVERTED  (1'b0),
    .IS_D1_INVERTED (1'b0),
    .IS_D2_INVERTED (1'b0),
    .SIM_DEVICE     ("ULTRASCALE_PLUS"),
    .SRVAL          (1'b0)
) adc_enc_oddr (
    .Q  (clk_fwd),
    .C  (clk),
    .D1 (1'b1),
    .D2 (1'b0),
    .SR (1'b0)
);

OBUFDS #(
    .IOSTANDARD ("LVDS"),
    .SLEW       ("FAST")
) adc_enc_obuf (
    .I  (clk_fwd),
    .O  (adc_encode_p),
    .OB (adc_encode_n)
);

endmodule
`default_nettype wire



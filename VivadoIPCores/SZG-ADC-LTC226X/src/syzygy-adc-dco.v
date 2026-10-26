`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-adc-dco.v
//
// Recovers the ADC data clock (DCO) and produces the ISERDES capture clocks:
// the bit clock (clk_out_bufio) and the /4 divided sample clock (clk_out_div).
//------------------------------------------------------------------------
// Copyright (c) 2022-2026 Opal Kelly Incorporated
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
    input  wire adc_dco_p,      // ADC Data clock
    input  wire adc_dco_n,

    output wire clk_out_bufio,  // bit clock (ISERDES CLK)
    output wire clk_out_div     // 1/4 clock rate for data from SERDES (ISERDES CLKDIV)
);

wire clk_out_int;               // IBUFDS output -> both BUFGCE_DIVs

IBUFDS #(
    .IOSTANDARD ("LVDS"),
    .DIFF_TERM  ("TRUE")
) adc_dco_ibufds (
    .I  (adc_dco_p),
    .IB (adc_dco_n),
    .O  (clk_out_int)
);

// Bit clock (CLK): DCO buffered /1.
BUFGCE_DIV #(
    .BUFGCE_DIVIDE   (1),
    .IS_CE_INVERTED  (1'b0),
    .IS_CLR_INVERTED (1'b0),
    .IS_I_INVERTED   (1'b0),
    .SIM_DEVICE      ("ULTRASCALE_PLUS")
) bufgce_div_bufio (
    .O   (clk_out_bufio),
    .CE  (1'b1),
    .CLR (1'b0),
    .I   (clk_out_int)
);

// Divided sample clock (CLKDIV): DCO buffered /4. Same source as the bit clock
// so the two stay phase-coherent.
BUFGCE_DIV #(
    .BUFGCE_DIVIDE   (4),
    .IS_CE_INVERTED  (1'b0),
    .IS_CLR_INVERTED (1'b0),
    .IS_I_INVERTED   (1'b0),
    .SIM_DEVICE      ("ULTRASCALE_PLUS")
) bufgce_div_slow (
    .O   (clk_out_div),
    .CE  (1'b1),
    .CLR (1'b0),
    .I   (clk_out_int)
);

endmodule
`default_nettype wire

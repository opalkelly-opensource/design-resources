//------------------------------------------------------------------------
// syzygy-adc-dco.v
//
// This module handles the data clock output from the ADC and provides the
// necessary signals required by the ISERDES input buffers.
// 
//------------------------------------------------------------------------
// Copyright (c) 2022-2024 Opal Kelly Incorporated
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
    
    output wire locked,

    output wire  clk_out_bufio,
    output wire  clk_out_div     // 1/4 clock rate for data from SERDES
    );

wire clk_out_int; // internal clock net
wire mmcm0_clkfb_bufg;
wire mmcm0_clkfb;

IBUFDS #(
    .IOSTANDARD ("LVDS"),
    .DIFF_TERM  ("TRUE")
) adc_dco_ibufds (
    .I  (adc_dco_p),
    .IB (adc_dco_n),
    .O  (clk_out_int)
);


MMCME4_BASE #(
    .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
    .CLKFBOUT_MULT_F(7.5),     // Multiply value for all CLKOUT (2.000-64.000).
    .CLKFBOUT_PHASE(0.000), // Phase offset in degrees of CLKFB (-360.000-360.000).
    .CLKIN1_PERIOD(6.250),         // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    .CLKOUT0_DIVIDE_F(7.5),    // Divide amount for CLKOUT0 (1.000-128.000).
    .CLKOUT1_DIVIDE(30),       // Divide amount for CLKOUT1
    .CLKOUT0_PHASE(0.0),       // Phase offset for each CLKOUT (-360.000-360.000).
    .DIVCLK_DIVIDE(1),         // Master division value (1-106)
    .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
    .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
)
mmcm_dco (
    .CLKOUT0(clk_out_bufio),   // 1-bit output: CLKOUT0
    .CLKOUT1(clk_out_div),     // 1-bit output: CLKOUT0
    .CLKFBOUT(mmcm0_clkfb),    // 1-bit output: Feedback clock
    .LOCKED(locked),                 // 1-bit output: LOCK
    .CLKIN1(clk_out_int),      // 1-bit input: Clock
    .RST(1'b0),                // 1-bit input: Reset
    .CLKFBIN(mmcm0_clkfb_bufg) // 1-bit input: Feedback clock
);

BUFG  mmcm0fb_bufg (.I(mmcm0_clkfb), .O(mmcm0_clkfb_bufg));

endmodule
`default_nettype wire
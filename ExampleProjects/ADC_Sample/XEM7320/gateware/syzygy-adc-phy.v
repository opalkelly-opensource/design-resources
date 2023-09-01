//------------------------------------------------------------------------
// syzygy-adc-phy.v
//
// This PHY interface converts the serial LVDS data streams out of the ADC
// into a parallel data output for use in the FPGA design. Xilinx 7-series
// ISERDES blocks are used to deserialize the ADC data.
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

module syzygy_adc_phy (
	input  wire                reset,

	input  wire [1:0]          adc_out_p, // Channel data
	input  wire [1:0]          adc_out_n,
	input  wire                adc_bufio_clk,
	input  wire                adc_slow_clk,

	input  wire                bitslip,

	output wire [15:0]         adc_data_out
	);

wire [1:0] adc_out, adc_delay;

IBUFDS #(
	.DIFF_TERM ("TRUE"),
	.IOSTANDARD ("LVDS_25")
) adc_ibufds0 (
	.I  (adc_out_p[0]),
	.IB (adc_out_n[0]),
	.O  (adc_out[0])
);

IBUFDS #(
	.DIFF_TERM ("TRUE"),
	.IOSTANDARD ("LVDS_25")
) adc_ibufds1 (
	.I  (adc_out_p[1]),
	.IB (adc_out_n[1]),
	.O  (adc_out[1])
);

IDELAYE2 #(
	.IDELAY_TYPE           ("FIXED"),
	.DELAY_SRC             ("IDATAIN"),
	.IDELAY_VALUE          (14), // a value of 14 should give ~1.1ns with a 200MHz reference
	.HIGH_PERFORMANCE_MODE ("TRUE"),
	.SIGNAL_PATTERN        ("DATA"),
	.REFCLK_FREQUENCY      (200),
	.CINVCTRL_SEL          ("FALSE"),
	.PIPE_SEL              ("FALSE")
) adc_data_delay0 (
	.C           (1'b0),
	.REGRST      (1'b0),
	.LD          (1'b0),
	.CE          (1'b0),
	.INC         (1'b0),
	.CINVCTRL    (1'b0),
	.CNTVALUEIN  (5'h00),
	.IDATAIN     (adc_out[0]),
	.DATAIN      (1'b0),
	.LDPIPEEN    (1'b0),
	.DATAOUT     (adc_delay[0]),
	.CNTVALUEOUT ()
);

IDELAYE2 #(
	.IDELAY_TYPE           ("FIXED"),
	.DELAY_SRC             ("IDATAIN"),
	.IDELAY_VALUE          (14), // a value of 14 should give ~1.1ns with a 200MHz reference
	.HIGH_PERFORMANCE_MODE ("TRUE"),
	.SIGNAL_PATTERN        ("DATA"),
	.REFCLK_FREQUENCY      (200),
	.CINVCTRL_SEL          ("FALSE"),
	.PIPE_SEL              ("FALSE")
) adc_data_delay1 (
	.C           (1'b0),
	.REGRST      (1'b0),
	.LD          (1'b0),
	.CE          (1'b0),
	.INC         (1'b0),
	.CINVCTRL    (1'b0),
	.CNTVALUEIN  (5'h00),
	.IDATAIN     (adc_out[1]),
	.DATAIN      (1'b0),
	.LDPIPEEN    (1'b0),
	.DATAOUT     (adc_delay[1]),
	.CNTVALUEOUT ()
);

ISERDESE2 #(
	.DATA_RATE         ("DDR"),
	.DATA_WIDTH        (8),
	.INTERFACE_TYPE    ("NETWORKING"), // Using internal clock network routing
	.DYN_CLKDIV_INV_EN ("FALSE"), // We do not need dynamic clocking
	.DYN_CLK_INV_EN    ("FALSE"), // We do not need dynamic clocking
	.NUM_CE            (1), // Only use CE1 as a clock enable
	.OFB_USED          ("FALSE"), // Only used for connection with OSERDESE2
	.IOBDELAY          ("BOTH"),
	.SERDES_MODE       ("MASTER")
) adc_serdes0 (
	.Q1        (adc_data_out[1]),
	.Q2        (adc_data_out[3]),
	.Q3        (adc_data_out[5]),
	.Q4        (adc_data_out[7]),
	.Q5        (adc_data_out[9]),
	.Q6        (adc_data_out[11]),
	.Q7        (adc_data_out[13]),
	.Q8        (adc_data_out[15]),
	.O         (),
	.SHIFTOUT1 (),
	.SHIFTOUT2 (),

	.D         (1'b0),
	.DDLY      (adc_delay[0]),

	.CLK       (adc_bufio_clk),
	.CLKB      (~adc_bufio_clk),
	.CE1       (1'b1),
	.CE2       (1'b0),

	.RST       (reset),

	.CLKDIV    (adc_slow_clk),
	.CLKDIVP   (1'b0),

	.OCLK      (1'b0),
	.OCLKB     (1'b0),

	.BITSLIP   (bitslip),

	.SHIFTIN1  (1'b0),
	.SHIFTIN2  (1'b0),
	.OFB       (1'b0),
	.DYNCLKDIVSEL (1'b0),
	.DYNCLKSEL    (1'b0)
);

ISERDESE2 #(
	.DATA_RATE         ("DDR"),
	.DATA_WIDTH        (8),
	.INTERFACE_TYPE    ("NETWORKING"), // Using internal clock network routing
	.DYN_CLKDIV_INV_EN ("FALSE"), // We do not need dynamic clocking
	.DYN_CLK_INV_EN    ("FALSE"), // We do not need dynamic clocking
	.NUM_CE            (1), // Only use CE1 as a clock enable
	.OFB_USED          ("FALSE"), // Only used for connection with OSERDESE2
	.IOBDELAY          ("BOTH"),
	.SERDES_MODE       ("MASTER")
) adc_serdes1 (
	.Q1        (adc_data_out[0]),
	.Q2        (adc_data_out[2]),
	.Q3        (adc_data_out[4]),
	.Q4        (adc_data_out[6]),
	.Q5        (adc_data_out[8]),
	.Q6        (adc_data_out[10]),
	.Q7        (adc_data_out[12]),
	.Q8        (adc_data_out[14]),
	.O         (),
	.SHIFTOUT1 (),
	.SHIFTOUT2 (),

	.D         (1'b0),
	.DDLY      (adc_delay[1]),

	.CLK       (adc_bufio_clk),
	.CLKB      (~adc_bufio_clk),
	.CE1       (1'b1),
	.CE2       (1'b0),

	.RST       (reset),

	.CLKDIV    (adc_slow_clk),
	.CLKDIVP   (1'b0),

	.OCLK      (1'b0),
	.OCLKB     (1'b0),

	.BITSLIP   (bitslip),

	.SHIFTIN1  (1'b0),
	.SHIFTIN2  (1'b0),
	.OFB       (1'b0),
	.DYNCLKDIVSEL (1'b0),
	.DYNCLKSEL    (1'b0)
);

endmodule
`default_nettype wire



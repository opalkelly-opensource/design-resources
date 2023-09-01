//------------------------------------------------------------------------
// syzygy-adc-frame.v
//
// An ISERDES connected to the ADC frame signal is used by this module to
// generate bitslip signals used to align the ADC data ISERDES outputs.
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

module syzygy_adc_frame (
	input  wire slow_clk,
	input  wire reset,

	input  wire adc_bufio_clk,
	input  wire adc_fr_p,
	input  wire adc_fr_n,

	output reg  data_valid,
	output reg  bitslip
	);

wire frame_input, frame_delay;
wire [7:0] frame_data;

// We must wait at least 3 clock cycles between each bitslip
reg  [1:0] wait_count;

always @(posedge slow_clk or posedge reset) begin
	if (reset == 1'b1) begin
		data_valid <= 1'b0;
		bitslip <= 1'b0;
		wait_count <= 2'b00;
	end else begin
		data_valid <= 1'b0;
		bitslip <= 1'b0;

		if (frame_data != 8'b11110000 && wait_count == 2'h0) begin
			bitslip    <= 1'b1;
			wait_count <= 2'h3;
		end else if (frame_data == 8'b11110000) begin
			data_valid <= 1'b1;
		end

		if (wait_count > 2'h0) begin
			wait_count <= wait_count - 1'b1;
		end
	end
end

IBUFDS #(
	.DIFF_TERM ("TRUE"),
	.IOSTANDARD ("LVDS_25")
) frame_ibufds (
	.I  (adc_fr_p),
	.IB (adc_fr_n),
	.O  (frame_input)
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
	.IDATAIN     (frame_input),
	.DATAIN      (1'b0),
	.LDPIPEEN    (1'b0),
	.DATAOUT     (frame_delay),
	.CNTVALUEOUT ()
);

ISERDESE2 #(
	.DATA_RATE         ("DDR"),
	.DATA_WIDTH        (8),
	.INTERFACE_TYPE    ("NETWORKING"), // Using internal clock network routing
	.DYN_CLKDIV_INV_EN ("FALSE"), // We do not need dynamic clocking
	.DYN_CLK_INV_EN    ("FALSE"), // We do not need dynamic clocking
	.NUM_CE            (1), // Only use CE1 as a clock enable
	.OFB_USED          ("FALSE"), //
	.IOBDELAY          ("BOTH"),
	.SERDES_MODE       ("MASTER")
) adc_serdes0 (
	.Q1        (frame_data[0]),
	.Q2        (frame_data[1]),
	.Q3        (frame_data[2]),
	.Q4        (frame_data[3]),
	.Q5        (frame_data[4]),
	.Q6        (frame_data[5]),
	.Q7        (frame_data[6]),
	.Q8        (frame_data[7]),
	.O         (),
	.SHIFTOUT1 (),
	.SHIFTOUT2 (),

	.D         (1'b0),
	.DDLY      (frame_delay),

	.CLK       (adc_bufio_clk),
	.CLKB      (~adc_bufio_clk),
	.CE1       (1'b1),
	.CE2       (1'b0),

	.RST       (reset),

	.CLKDIV    (slow_clk),
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



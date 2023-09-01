//------------------------------------------------------------------------
// syzygy-adc-top.v
//
// This top level module integrates the various components of the ADC
// portion of the design. These include the ADC encode signal output, ADC
// data clock input, and ISERDES buffers to handle data coming from the
// ADC.
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

module syzygy_adc_top (
	input  wire                clk,
	input  wire                idelay_ref,
	input  wire                reset_async,

	// ADC Pins
	input  wire [1:0]          adc_out_1p, // Channel 1 data
	input  wire [1:0]          adc_out_1n,
	input  wire [1:0]          adc_out_2p, // Channel 2 data
	input  wire [1:0]          adc_out_2n,
	input  wire                adc_dco_p,      // ADC Data clock
	input  wire                adc_dco_n,
	input  wire                adc_fr_p,       // Frame input
	input  wire                adc_fr_n,
	output wire                adc_encode_p,   // ADC Encode Clock
	output wire                adc_encode_n,
	input  wire                adc_sdo,
	output wire                adc_sdi,
	output wire                adc_cs_n,
	output wire                adc_sck,

	output wire                adc_data_clk,
	output wire [15:0]         adc_data_1,
	output wire [15:0]         adc_data_2,
	output wire                data_valid,
	
	output wire                idelay_rdy
	
	//output wire                overflow1,
	//output wire                overflow2
	);

wire adc_frame, bufio_clk;
wire bitslip;
reg  reset_sync;
reg  reset_idelay = 1'b1;

wire [13:0] adc_data1, adc_data2;
reg  [7:0]  reset_idelay_cnt = 8'h10;
reg  [7:0]  reset_serdes_cnt = 8'h10;

// This example doesn't use the ADC SPI bus,
// the default settings work fine
assign adc_sdi  = 1'b1;
assign adc_cs_n = 1'b1;
assign adc_sck  = 1'b1;

// Logic reset, must be held for at least two clock cycles to
// fully reset the ISERDES blocks
always @(posedge adc_data_clk or posedge reset_async) begin
	if(reset_async == 1'b1) begin
		reset_sync <= 1'b1;
		reset_serdes_cnt <= 8'h10;
	end else begin
		if (reset_serdes_cnt > 00) begin
			reset_serdes_cnt <= reset_serdes_cnt - 1'b1;
			reset_sync <= 1'b1;
		end else begin
			reset_sync <= 1'b0;
		end
	end
end

// IDELAYCTRL reset, must be asserted for T_IDELAYCTRL_RPW (60ns)
// Must be asserted after configuration
// With a 200MHz input this must be held for 12 cycles minimum
always @(posedge idelay_ref or posedge reset_async) begin
	if(reset_async == 1'b1) begin
		reset_idelay <= 1'b1;
		reset_idelay_cnt <= 8'd16;
	end else begin
		if (reset_idelay_cnt > 8'h00) begin
			reset_idelay_cnt <= reset_idelay_cnt - 1'b1;
			reset_idelay <= 1'b1;
		end else begin
			reset_idelay <= 1'b0;
		end
	end
end

syzygy_adc_phy adc_phy1_impl (
	.reset         (reset_sync),
	
	.adc_out_p     (adc_out_1p),
	.adc_out_n     (adc_out_1n),
	.adc_bufio_clk (bufio_clk),
	.adc_slow_clk  (adc_data_clk),

	.bitslip       (bitslip),

	.adc_data_out  (adc_data_1)
);

syzygy_adc_phy adc_phy2_impl (
	.reset         (reset_sync),
	
	.adc_out_p     (adc_out_2p),
	.adc_out_n     (adc_out_2n),
	.adc_bufio_clk (bufio_clk),
	.adc_slow_clk  (adc_data_clk),

	.bitslip       (bitslip),

	.adc_data_out  (adc_data_2)
);

syzygy_adc_dco adc_dco_impl (
	.reset         (reset_async),
	.adc_dco_p     (adc_dco_p),
	.adc_dco_n     (adc_dco_n),
	.clk_out_bufio (bufio_clk),
	.clk_out_div   (adc_data_clk)
);

syzygy_adc_frame adc_frame_impl (
	.slow_clk   (adc_data_clk),
	.reset      (reset_sync),
	
	.adc_bufio_clk (bufio_clk),
	.adc_fr_p   (adc_fr_p),
	.adc_fr_n   (adc_fr_n),

	.data_valid (data_valid),
	.bitslip    (bitslip)
);

syzygy_adc_enc adc_enc_impl (
	.clk          (clk),

	.adc_encode_p (adc_encode_p),
	.adc_encode_n (adc_encode_n)
);

IDELAYCTRL idelay_adc (
	.RST    (reset_idelay),
	.REFCLK (idelay_ref),
	.RDY    (idelay_rdy)
);

endmodule
`default_nettype wire


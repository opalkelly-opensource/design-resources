//------------------------------------------------------------------------
// signal-gen-top.v
//
// This is the top level module for the XEM7320 signal generator sample.
// This module interfaces between the DAC itself and the audio sources 
// (a FrontPanel PipeIn endpoint and an ADC PMOD).
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

module signal_gen_top(
	// FrontPanel Connections
	input  wire [4:0]  okUH,
	output wire [3:0]  okHU,
	input  wire [3:0]  okRSVD,
	inout  wire [31:0] okUHU,
	inout  wire        okAA,

	// DAC Connections
	output wire [11:0] dac_data,        // I/Q Data
	output wire        dac_clk,
	output wire        dac_reset_pinmd,
	output wire        dac_sclk,        // SPI Clock
	inout  wire        dac_sdio,        // SPI Data I/O
	output wire        dac_cs_n,        // SPI Chip Select

	// I2S2 PMOD Connections
	output wire        i2s2_rx_mclk,    // Master Clock
	output wire        i2s2_rx_lrck,    // Word Select
	output wire        i2s2_rx_sclk,    // Serial Clock
	input  wire        i2s2_rx_sdin,    // Data Input

	output wire [7:0]  led
);

// LEDs //
function [7:0] xem7320_led;
	input [7:0] a;
	integer i;
	begin
		for(i = 0; i < 8; i =i + 1) begin: u
			xem7320_led[i] = (a[i]==1'b1) ? (1'b0) : (1'bz);
		end
	end
endfunction

// FrontPanel //
// Target Interface Bus
wire            okClk;
wire [112:0]    okHE;
wire [64:0]     okEH;
wire [65*1-1:0] okEHx;

wire [31:0]     ep00wire, ep01wire, ep02wire, ep03wire, ep04wire, ep05wire;
wire            pipe_in_write;
wire [31:0]     pipe_in_data;
wire            dis_am;
wire            dis_fm;

assign          dis_am        = ep03wire[0];
assign          dis_fm        = ep03wire[1];

reg             int_reset     = 1'd1;
reg  [3:0]      reset_count;

// Audio
wire            data_select   = ep00wire[4];
// ADC
wire [23:0]     adc_data;
reg  [23:0]     adc_data_r;
// FIFO
wire [31:0]     dout;
wire [9:0]      data_count;
wire            empty, full;
reg             rd_en;
reg  [32:0]     dout_r;
reg  [31:0]     dout_left, dout_right;
reg  [15:0]     rd_en_count;
reg             side;

wire [11:0]     audio_data;
wire            pipe_in_ready;

assign          audio_data    = (data_select) ? dout_r[31:20] : adc_data_r[23:12];
assign          pipe_in_ready = (data_count < 11'd1024 - 9'd256) ? 1'b1 : 1'b0;

// General
wire            mst_reset;
assign          mst_reset     = ep00wire[0] | int_reset;

// lEDs
assign          led           = xem7320_led({empty, full});

// FrontPanel Host Connections
okHost okHI(
	.okUH   (okUH),
	.okHU   (okHU),
	.okRSVD (okRSVD),
	.okUHU  (okUHU),
	.okAA   (okAA),
	.okClk  (okClk),
	.okHE   (okHE), 
	.okEH   (okEH)
);

okWireOR #(.N(1)) wireOR (okEH, okEHx);

// Button wire (5 bit used)
okWireIn   wi00(.okHE(okHE), .ep_addr(8'h00), .ep_dataout(ep00wire));
// Frequency wire (32 bits used)
okWireIn   wi01(.okHE(okHE), .ep_addr(8'h01), .ep_dataout(ep01wire));
// Depth wire (8 bits used)
okWireIn   wi02(.okHE(okHE), .ep_addr(8'h02), .ep_dataout(ep02wire));
// Amplitude selection wire
okWireIn   wi03(.okHE(okHE), .ep_addr(8'h03), .ep_dataout(ep03wire));
// Frequency deviation wire (16 bits used)
okWireIn   wi04(.okHE(okHE), .ep_addr(8'h04), .ep_dataout(ep04wire));
// Read enable count wire (16 bits used)
okWireIn   wi05(.okHE(okHE), .ep_addr(8'h05), .ep_dataout(ep05wire));
// Bulk audio transfer pipe
okBTPipeIn ep80(
	.okHE           (okHE),
	.okEH           (okEHx[0 * 65 +: 65]),
	.ep_addr        (8'h80),
	.ep_write       (pipe_in_write),
	.ep_blockstrobe (),
	.ep_dataout     (pipe_in_data),
	.ep_ready       (pipe_in_ready)
);

// SYZYGY DAC //
syzygy_dac_top szg_dac(
	.clk             (okClk),
	.reset           (mst_reset),

	.freq            (ep01wire),
	.freq_dev        (ep04wire),
	.ampl            (audio_data),
	.depth           (ep02wire),
	.dis_out         (ep00wire[1]),
	.dis_am          (dis_am),
	.dis_fm          (dis_fm),

	.dac_data        (dac_data),
	.dac_clk         (dac_clk),
	.dac_reset_pinmd (dac_reset_pinmd),
	.dac_sclk        (dac_sclk),
	.dac_sdio        (dac_sdio),
	.dac_cs_n        (dac_cs_n)
);

// I2S2 ADC PMOD //
szg_i2s2_pmod_top szg_i2s2(
	.clk      (okClk),
	.reset    (mst_reset),

	.rx_mclk  (i2s2_rx_mclk),
	.rx_lrck  (i2s2_rx_lrck),
	.rx_sclk  (i2s2_rx_sclk),
	.rx_sdin  (i2s2_rx_sdin),

	.data     (adc_data)
);

// FIFO //
fifo_generator_0 fifo(
	.clk        (okClk),
	.srst       (mst_reset),
	// FIFO_WRITE
	.full       (full),
	.din        (pipe_in_data),
	.wr_en      (pipe_in_write),
	// FIFO_READ
	.empty      (empty),
	.dout       (dout),
	.rd_en      (rd_en),
	// Data Count
	.data_count (data_count)
);


// Gate data from FIFO to resample at the audio sample rate
always @(posedge okClk) begin
	if (mst_reset) begin
		adc_data_r  <= 32'd0;
		dout_r      <= 33'd0;
		dout_left   <= 32'd0;
		dout_right  <= 32'd0;
		rd_en       <= 1'd0;
		side        <= 1'd0;
		rd_en_count <= 32'd0;

		// Hold reset for 15 cycles
		if (reset_count == 4'd14)
			int_reset   <= 1'd0;
		else
			reset_count <= reset_count + 1;
	end else begin
		adc_data_r  <= adc_data;
		dout_r      <= (dout_right + dout_left) / 2;

		if (rd_en_count == ep05wire) begin
			rd_en       <= 1'b1;
			if (side) begin
				dout_right  <= dout;
				side        <= 1'b0;
				rd_en_count <= 16'd0;
			end else begin
				dout_left   <= dout;
				side        <= 1'b1;
			end

		end else begin
			rd_en       <= 1'b0;
			rd_en_count <= rd_en_count + 1;
		end
	end
end

endmodule

`default_nettype wire

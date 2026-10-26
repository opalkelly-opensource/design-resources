`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-adc-spi.v
//
// SPI interface for the LTC2264 / LTC2268 on the SYZYGY ADC Pod.
//
// This module can be controlled through the spi_* signals. Set an LTC
// configuration-register address with the 'spi_reg' signal, along with the
// data to send on 'spi_data_in'. Pulsing 'spi_send' high begins a SPI
// transaction; 'spi_rw' selects its direction (0 = write, 1 = read).
//
// The 'spi_done' signal indicates that a transaction has completed and that
// the engine is ready to start a new one. It also serves as the "data valid"
// indicator for the 'spi_data_out' bus (populated on reads).
//
// 4-wire: SDI is always an FPGA output and SDO always an FPGA input, sampled
// during the data byte of a read.
//
// LTC framing (see the LTC2264/LTC2268 datasheet, "Serial Programming Mode"):
// a transfer is two bytes, MSB first. The first byte is the instruction
// {R/W, A6:A0} -- R/W = 1 reads, 0 writes; A6:A0 is the 7-bit register
// address. The second byte is the data.
//
// SCLK idles High. CS_B falls first, then SDI is launched on each falling edge
// and the LTC samples it on the following rising edge, 16 edges of each. SDO is
// captured on rising edges 9..16.
//
// The R/W polarity is taken from the datasheet and not yet measured. If it is
// inverted, a read writes the stale spi_data_in byte to the addressed register,
// and register 0x00 bit 7 is the LTC software reset.
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

module syzygy_adc_spi #(
	// SCLK = clk / (2 * (SCLK_DIV + 1)). LTC SCLK max is ~20 MHz.
	parameter integer SCLK_DIV = 125
)(
	input  wire        clk,
	input  wire        reset,

	// ADC SPI pads
	output wire        adc_sclk,
	output wire        adc_sdi,   // FPGA -> ADC (configuration / instruction)
	input  wire        adc_sdo,   // ADC  -> FPGA (register read-back)
	output wire        adc_cs_n,

	// Control signals for this module
	input  wire [6:0]  spi_reg,       // 7-bit LTC register address
	input  wire [7:0]  spi_data_in,
	output reg  [7:0]  spi_data_out,
	input  wire        spi_send,
	output reg         spi_done,
	input  wire        spi_rw         // 0 = write, 1 = read
	);

localparam integer DIV_CNT_W = $clog2(SCLK_DIV + 1);
reg  [DIV_CNT_W-1:0] divide_counter;
reg         clk_en, spi_done_r;

wire [7:0]  instruction_word;
wire [15:0] full_transfer_word;

reg         spi_pin_out;
wire        spi_pin_in;

// current position in the SPI data stream
reg  [4:0]  spi_pos;

// Internal (pre-buffer) pin drivers; the I/O buffers at the bottom of the
// module connect these to the pads.
reg         adc_sclk_int;
reg         adc_cs_n_int;
wire        adc_sdi_int;   // SDI buffer input  (to   OBUF.I)
wire        adc_sdo_int;   // SDO buffer output (from IBUF.O)

// SPI instruction byte: {R/W, A6:A0}. R/W = spi_rw (1 reads, 0 writes);
// spi_reg is the 7-bit register address.
assign instruction_word   = {spi_rw, spi_reg};

assign full_transfer_word = {instruction_word, spi_data_in};

assign adc_sdi_int        = spi_pin_out;   // SDI is always driven (4-wire)
assign spi_pin_in         = adc_sdo_int;

// Divide down the input clock to generate the SCLK toggle rate.
always @(posedge clk) begin
	clk_en <= 1'b0;
	if (reset) begin
		divide_counter <= {DIV_CNT_W{1'b0}};
	end else begin
		divide_counter <= divide_counter + 1'd1;

		if (divide_counter == SCLK_DIV) begin
			divide_counter <= {DIV_CNT_W{1'b0}};
			clk_en         <= 1'b1;
		end
	end
end

// Handle the SPI transfer.
always @(posedge clk) begin
	if (reset == 1'b1) begin
		adc_sclk_int  <= 1'b1;
		adc_cs_n_int  <= 1'b1;

		spi_data_out  <= 8'h00;
		spi_done      <= 1'b1;
		spi_done_r    <= 1'b1;

		spi_pin_out   <= 1'b0;
		spi_pos       <= 5'h0;
	end else begin
		if (clk_en) begin
			adc_sclk_int   <= ~adc_sclk_int;

			// SCLK falling edge: launch the next SDI bit. The LTC samples SDI on
			// the rising edge, half a period later.
			if (adc_sclk_int) begin
				if (spi_pos > 5'h0) begin
					spi_pos     <= spi_pos - 1'b1;
					spi_done    <= 1'b0;
					spi_done_r  <= 1'b0;
					// Load the next output bit only while a frame is active,
					// so SDI holds the last bit (not junk) after the frame.
					spi_pin_out <= full_transfer_word[spi_pos - 1];
				end else begin
					adc_cs_n_int <= 1'b1;
					spi_done_r   <= 1'b1;
					spi_done     <= spi_done_r;
					adc_sclk_int <= 1'b1;
				end
			end

			// SCLK rising edge: capture SDO for the data byte. spi_pos was already
			// decremented by the falling edge that opened this bit period, so it IS
			// the destination index -- rising edges 9..16 capture D7..D0. On a write
			// the LTC does not drive SDO and the captured byte is ignored.
			//
			// Sample point: this tick reads correctly whichever edge the LTC
			// launches read data on:
			//   * falling edge: the bit has been on the pin for half an SCLK
			//     period and has half a period left.
			//   * rising edge: the bit has been on the pin for a full SCLK
			//     period, and its successor cannot reach this pin until a round
			//     trip after this clk edge.
			// The falling tick returns {junk, D7..D2} for the first case.
			//
			// spi_pin_in has no synchronizer, since one would move the sample
			// point. The pin has been stable for at least SCLK_DIV+1 clk cycles
			// when sampled.
			else if (spi_pos < 5'h8 && !adc_cs_n_int) begin
				spi_data_out[spi_pos] <= spi_pin_in;
			end
		end

		// Start an SPI transfer. Must stay after the shift logic above: a start
		// that coincides with a clk_en idle tick has to override its CS/done
		// assignments.
		if (spi_send && spi_done) begin
			spi_pos      <= 5'h10;
			adc_sclk_int <= 1'b1;
			adc_cs_n_int <= 1'b0;
			spi_done     <= 1'b0;
			spi_done_r   <= 1'b0;
		end
	end
end

// No IOSTANDARD here: the SYZYGY board flow sets the SPI logic level.
OBUF obuf_adc_sclk (.I(adc_sclk_int), .O(adc_sclk));
OBUF obuf_adc_cs_n (.I(adc_cs_n_int), .O(adc_cs_n));
OBUF obuf_adc_sdi  (.I(adc_sdi_int),  .O(adc_sdi));
IBUF ibuf_adc_sdo  (.I(adc_sdo),      .O(adc_sdo_int));

endmodule

`default_nettype wire

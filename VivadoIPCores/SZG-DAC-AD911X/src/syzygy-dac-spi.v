`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-dac-spi.v
//
// SPI interface for the AD911x on the SYZYGY DAC Pod.
//
// This module can be controlled through the spi_* signals.
// Set a DAC configuration register address with the 'spi_reg' signal,
// along with the desired data to send on the 'spi_data_in' signal.
// Setting the 'spi_send' signal high will begin a SPI transaction.
// The direction of a transfer is controlled with the 'spi_rw' signal.
//
// The 'spi_done' signal is used to indicate that a transaction has
// completed and that the controller is ready to start a new transaction.
// This signal can also be used as a "data valid" indicator for the
// 'spi_data_out' bus.
//
//------------------------------------------------------------------------
// Copyright (c) 2024-2026 Opal Kelly Incorporated
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

module syzygy_dac_spi #(
	// Number of clk cycles between SCLK toggles minus one.
	// SCLK frequency = clk_freq / (2 * (SCLK_DIV + 1)).
	parameter integer SCLK_DIV = 125
)(
	input  wire        clk,
	input  wire        reset,

	output wire        dac_sclk,
	inout  wire        dac_sdio,
	output wire        dac_cs_n,
	output wire        dac_reset_pinmd,

	// Control signals for this module
	input  wire [4:0]  spi_reg,
	input  wire [7:0]  spi_data_in,
	output reg  [7:0]  spi_data_out,
	input  wire        spi_send,
	output reg         spi_done,
	input  wire        spi_rw // 0 = write, 1 = read (AD911x instruction bit 7)
	);

localparam integer DIV_CNT_W = $clog2(SCLK_DIV + 1);
reg  [DIV_CNT_W-1:0] divide_counter;
reg         clk_en, spi_done_r;

wire [7:0]  instruction_word;
wire [15:0] full_transfer_word;

reg         spi_data_dir, spi_pin_out;
wire        spi_pin_in;

reg  [4:0]  spi_pos;

// Internal (pre-buffer) pin drivers; the I/O buffers at the bottom of the module
// connect these to the pads.
reg         dac_sclk_int;
reg         dac_cs_n_int;
reg         dac_reset_int;
wire        dac_sdio_i;   // SDIO buffer input  (from IOBUF.O)
wire        dac_sdio_o;   // SDIO buffer output (to   IOBUF.I)
wire        dac_sdio_t;   // SDIO tristate ctrl (to   IOBUF.T), 1 = high-Z

// SPI instruction byte: {R/W, N1, N0, A4:A0}. N1:N0 = 2'b00 selects a 1-byte
// transfer; spi_reg is the 5-bit register address (A4:A0).
assign instruction_word   = {spi_rw, 2'b00, spi_reg};

assign full_transfer_word = {instruction_word, spi_data_in};

assign dac_sdio_o         = spi_pin_out;
assign dac_sdio_t         = ~spi_data_dir;   // drive when spi_data_dir, else high-Z
assign spi_pin_in         = dac_sdio_i;

// SCLK divider: clk_en pulses once per SCLK half-period.
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

// Handle the SPI transfer
always @(posedge clk) begin
	if (reset == 1'b1) begin
		dac_sclk_int  <= 1'b1;
		dac_cs_n_int  <= 1'b1;
		dac_reset_int <= 1'b1;

		spi_data_out  <= 8'h00;
		spi_done      <= 1'b1;
		spi_done_r    <= 1'b1;

		spi_data_dir  <= 1'b0;
		spi_pin_out   <= 1'b0;
		spi_pos       <= 5'h0;
	end else begin
		dac_reset_int <= 1'b0;

		if (clk_en) begin
			spi_data_dir   <= 1'b1;

			// Read turnaround: release SDIO at the falling edge that ends
			// the instruction byte
			if (spi_rw == 1'b1 &&
			    ((spi_pos < 8) || (spi_pos == 5'h8 && dac_sclk_int))) begin
				spi_data_dir <= 1'b0;
			end

			dac_sclk_int   <= ~dac_sclk_int;

			if (dac_sclk_int) begin
				if (spi_pos > 5'h0) begin
					spi_pos     <= spi_pos - 1'b1;
					spi_done    <= 1'b0;
					spi_done_r  <= 1'b0;
					spi_pin_out <= full_transfer_word[spi_pos - 1];
				end else begin
					dac_cs_n_int <= 1'b1;
					spi_done_r   <= 1'b1;
					spi_done     <= spi_done_r;
					dac_sclk_int <= 1'b1;
				end

				// Sample SDIO during the data byte.
				if (spi_pos < 8 && !dac_cs_n_int) begin
					spi_data_out[spi_pos] <= spi_pin_in;
				end
			end
		end

		// Start an SPI transfer.
		if (spi_send && spi_done) begin
			spi_pos      <= 5'h10;
			dac_sclk_int <= 1'b1;
			dac_cs_n_int <= 1'b0;
			spi_done     <= 1'b0;
			spi_done_r   <= 1'b0;
		end
	end
end

// I/O buffers for the single-ended SPI / control pins.
OBUF  #(.IOSTANDARD("LVCMOS18")) obuf_dac_sclk  (.I(dac_sclk_int),  .O(dac_sclk));
OBUF  #(.IOSTANDARD("LVCMOS18")) obuf_dac_cs_n  (.I(dac_cs_n_int),  .O(dac_cs_n));
OBUF  #(.IOSTANDARD("LVCMOS18")) obuf_dac_reset (.I(dac_reset_int), .O(dac_reset_pinmd));
IOBUF #(.IOSTANDARD("LVCMOS18")) iobuf_dac_sdio (.IO(dac_sdio), .I(dac_sdio_o), .O(dac_sdio_i), .T(dac_sdio_t));

endmodule

`default_nettype wire

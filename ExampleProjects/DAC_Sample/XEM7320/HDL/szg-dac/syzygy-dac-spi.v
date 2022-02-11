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

module syzygy_dac_spi(
	input  wire        clk,
	input  wire        reset,

	// DAC SPI interface
	output reg         dac_sclk,
	inout  wire        dac_sdio,
	output reg         dac_cs_n,
	output reg         dac_reset,

	// Control signals for this module
	input  wire [5:0]  spi_reg,
	input  wire [7:0]  spi_data_in,
	output reg  [7:0]  spi_data_out,
	input  wire        spi_send,
	output reg         spi_done,
	input  wire        spi_rw // 0 = read, 1 = write
	);

reg  [31:0] divide_counter;
reg         clk_en, spi_done_r;

wire [7:0]  instruction_word;
wire [15:0] full_transfer_word;

reg         spi_data_dir, spi_pin_out;
wire        spi_pin_in;

// current position in the SPI data stream
reg  [5:0]  spi_pos;

// Construct the instruction word from its components
// Always just transfer a single byte (second portion = 00)
assign instruction_word   = {spi_rw, 2'b00, spi_reg};

assign full_transfer_word = {instruction_word, spi_data_in};

assign dac_sdio           = (spi_data_dir) ? (spi_pin_out) : (1'bZ);
assign spi_pin_in         = dac_sdio;

// Divide down the ~125MHz input clock to ~1MHz to work with the SPI interface
always @(posedge clk) begin
	clk_en <= 1'b0;
	if (reset) begin
		divide_counter <= 32'h00;
	end else begin
		divide_counter <= divide_counter + 1'd1;

		if (divide_counter == 32'd125) begin
			divide_counter <= 32'h00;
			clk_en         <= 1'b1;
		end
	end
end

// Handle the SPI transfer
always @(posedge clk) begin
	if (reset == 1'b1) begin
		dac_sclk     <= 1'b1;
		dac_cs_n     <= 1'b1;
		dac_reset    <= 1'b1;

		spi_data_out <= 8'h00;
		spi_done     <= 1'b1;
		spi_done_r   <= 1'b1;

		spi_data_dir <= 1'b0;
		spi_pin_out  <= 1'b0;
		spi_pos      <= 6'h0;
	end else begin
		dac_reset    <= 1'b0;

		// start an SPI transfer
		if (spi_send && spi_done) begin
			spi_pos        <= 5'h10;
			dac_sclk       <= 1'b1;
			dac_cs_n       <= 1'b0;
			spi_done       <= 1'b0;
			spi_done_r     <= 1'b0;
		end

		if (clk_en) begin
			spi_data_dir   <= 1'b1;
			
			if (spi_rw == 1'b1 && spi_pos < 8) begin
				spi_data_dir <= 1'b0;
			end

			dac_sclk       <= ~dac_sclk;

			if (dac_sclk) begin
				if (spi_pos > 6'h0) begin
					spi_pos               <= spi_pos - 1'b1;
					spi_done              <= 1'b0;
					spi_done_r            <= 1'b0;
				end else begin
					dac_cs_n              <= 1'b1;
					spi_done_r            <= 1'b1;
					spi_done              <= spi_done_r;
					dac_sclk              <= 1'b1;
				end

				spi_pin_out  <= full_transfer_word[spi_pos - 1];

				if (spi_pos < 8) begin
					spi_data_out[spi_pos] <= spi_pin_in;
				end
			end
		end
	end
end

endmodule

`default_nettype wire

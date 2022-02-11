//------------------------------------------------------------------------
// spi_control.v
//
// Basic, configurable SPI interface for FrontPanel devices.
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

module spi_control (
	input  wire        clk,
	input  wire        reset,

	// SPI interface
	output reg         sclk,
	input  wire        miso,
	output reg         mosi,
	output reg         miso_mosi_dir, // can be used for bidirectional sdio
	output reg         cs_n,

	// Control signals for this module
	input  wire [6:0]  spi_reg,
	input  wire [7:0]  spi_data_in,
	output reg  [7:0]  spi_data_out,
	input  wire        spi_send,
	output reg         spi_done,
	input  wire        spi_rw // 1 = read, 0 = write
	);
	
parameter DIVIDE_COUNT = 32'd125;

reg  [31:0] divide_counter;
reg         clk_en, spi_done_r;

wire [7:0]  instruction_word;
wire [15:0] full_transfer_word;

// current position in the SPI data stream
reg  [5:0] spi_pos;

// Construct the instruction word from its components
// Always just transfer a single byte (second portion = 00)
assign instruction_word = {spi_rw, spi_reg};

assign full_transfer_word = {instruction_word, spi_data_in};

// Divide down the ~125MHz input clock to ~1MHz to work with the SPI interface
always @(posedge clk) begin
	if (reset == 1'b1) begin
		divide_counter <= 32'h00;
		clk_en <= 1'b0;
	end else begin
		divide_counter <= divide_counter + 1'b1;
		clk_en <= 1'b0;

		if (divide_counter == DIVIDE_COUNT) begin
			divide_counter <= 32'h00;
			clk_en <= 1'b1;
		end
	end
end

// Handle the SPI transfer
always @(posedge clk) begin
	if (reset == 1'b1) begin
		sclk <= 1'b1;
		cs_n <= 1'b1;

		spi_data_out <= 8'h00;
		spi_done     <= 1'b1;
		spi_done_r   <= 1'b1;

		miso_mosi_dir <= 1'b0;
		mosi          <= 1'b1;
		spi_pos       <= 6'h0;
	end else begin
		// start an SPI transfer
		if (spi_send == 1'b1 && spi_done == 1'b1) begin
			spi_pos <= 5'h10;
			sclk <= 1'b1;
			cs_n <= 1'b0;
			spi_done <= 1'b0;
			spi_done_r <= 1'b0;
		end

		if (clk_en == 1'b1) begin
			if (spi_rw == 1'b1 && spi_pos <= 8) begin
				miso_mosi_dir <= 1'b0;
			end else begin
				miso_mosi_dir <= 1'b1;
			end
			

			sclk <= ~sclk;

			if (sclk == 1'b1) begin
				if (spi_pos > 6'h0) begin
					spi_pos  <= spi_pos - 1'b1;
					spi_done <= 1'b0;
					spi_done_r <= 1'b0;
				end else begin
					cs_n <= 1'b1;
					spi_done_r <= 1'b1;
					spi_done <= spi_done_r;
					sclk <= 1'b1;
				end
				
				mosi <= full_transfer_word[spi_pos - 1];
			end
			
			if (sclk == 1'b0) begin
				if (spi_pos < 8) begin
					spi_data_out[spi_pos] <= miso;
				end
			end
		end
	end
end

endmodule
`default_nettype wire

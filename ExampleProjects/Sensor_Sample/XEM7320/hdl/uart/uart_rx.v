//------------------------------------------------------------------------
// uart_rx.v
//
// Simple UART receive module, can be controlled through the FrontPanel
// interface.
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
//
//------------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module uart_rx(
	input  wire       clk,
	input  wire       reset,

	input  wire       uart_rx,

	output reg  [7:0] uart_data,
	output reg        byte_received
);

parameter CLK_DIV = 13020; // Must divide down to 9600 Hz

reg [31:0] div_count;
reg        div_enable;

reg [ 7:0] bit_counter;
reg [ 7:0] bit_pos;
reg [ 7:0] uart_data_int;

always @(posedge clk) begin
	if (reset == 1'b1) begin
		div_count <= 32'h0;
		div_enable <= 1'b0;
	end else begin
		div_count <= div_count - 1'b1;
		div_enable <= 1'b0;

		if (div_count == 32'h0) begin
			div_count <= CLK_DIV / 8; // we want to be 8x baud rate
			div_enable <= 1'b1;
		end
	end
end


reg [31:0] state;
localparam s_wait_start  = 0,
           s_count_start = 1,
           s_read_bit    = 2,
		   s_wait_bit    = 3,
		   s_done        = 4;

always @(posedge clk) begin
	if (reset == 1'b1) begin
		uart_data     <= 8'h00;
		byte_received <= 8'h00;
		bit_counter   <= 8'h00;
		bit_pos       <= 8'h00;
		state         <= s_wait_start;
	end else begin
		byte_received <= 1'b0;

		if (div_enable == 1'b1) begin
			case (state)
				s_wait_start: begin
					bit_pos <= 8'h0;

					if(uart_rx == 1'b0) begin
						state <= s_count_start;
						bit_counter <= 8'h2;
					end
				end

				s_count_start: begin
					if (uart_rx == 1'b0) begin
						bit_counter <= bit_counter - 1'b1;

						if (bit_counter == 8'h0) begin
							state <= s_wait_bit;
							bit_counter <= 8'h6;
						end
					end else begin
						state <= s_count_start;
					end
				end

				s_read_bit: begin
					uart_data_int[bit_pos] <= uart_rx;
					state <= s_wait_bit;
					bit_counter <= 8'h6;
					bit_pos <= bit_pos + 1'b1;

					if (bit_pos == 8'h7) begin
						state <= s_done;
					end
				end

				s_wait_bit: begin
					bit_counter <= bit_counter - 1'b1;

					if (bit_counter == 8'h0) begin
						state <= s_read_bit;
						bit_counter <= 8'h0;
					end
				end

				s_done: begin
					bit_counter <= bit_counter - 1'b1;
					if(bit_counter == 8'h0) begin
						byte_received <= 1'b1;
						uart_data <= uart_data_int;
						state <= s_wait_start;
					end
				end
			endcase
		end
	end
end

endmodule

`default_nettype wire

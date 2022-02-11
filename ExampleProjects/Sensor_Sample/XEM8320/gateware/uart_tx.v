//------------------------------------------------------------------------
// uart_tx.v
//
// Simple UART transmit module, can be controlled through the FrontPanel
// interface.
//
//------------------------------------------------------------------------
// Copyright (c) 2021 Opal Kelly Incorporated
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

module uart_tx(
	input  wire       clk,
	input  wire       reset,

	output reg        uart_tx,

	input  wire [7:0] uart_data,
	output reg        uart_done,
	input  wire       send_byte
);

parameter CLK_DIV = 13020; // Must divide down to 9600 Hz

reg [31:0] div_count;
reg        div_enable;

reg [ 7:0] bit_pos;

always @(posedge clk) begin
	if (reset == 1'b1) begin
		div_count <= 32'h0;
		div_enable <= 1'b0;
	end else begin
		div_count <= div_count - 1'b1;
		div_enable <= 1'b0;

		if (div_count == 32'h0) begin
			div_count <= CLK_DIV;
			div_enable <= 1'b1;
		end
	end
end


reg [31:0] state;
localparam s_wait_start = 0,
           s_start      = 1,
           s_send_bit   = 2,
		   s_done       = 3;

always @(posedge clk) begin
	if (reset == 1'b1) begin
		uart_tx   <= 1'b1;
		bit_pos   <= 8'h0;
		state     <= s_wait_start;
		uart_done <= 1'b1;
	end else begin
		if ((state == s_wait_start) && (send_byte == 1'b1)) begin
			state <= s_start;
			bit_pos <= 8'h0;
			uart_done <= 1'b0;
		end
		
		if (state == s_wait_start) begin
			uart_done <= 1'b1;
		end else begin
			uart_done <= 1'b0;
		end

		if (div_enable == 1'b1) begin
			case (state)
				s_start: begin
					uart_tx <= 1'b0;
					state <= s_send_bit;
					bit_pos <= 8'h0;
				end

				s_send_bit: begin
					uart_tx <= uart_data[bit_pos];
					bit_pos <= bit_pos + 1'b1;

					if (bit_pos == 8'h7) begin
						state <= s_done;
					end
				end

				s_done: begin
					uart_tx <= 1'b1;
					state <= s_wait_start;
				end
			endcase
		end
	end
end

endmodule

`default_nettype wire

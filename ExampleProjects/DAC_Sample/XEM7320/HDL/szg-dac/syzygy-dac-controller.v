//------------------------------------------------------------------------
// syzygy-dac-controller.v
//
// SPI controller for the SYZYGY DAC Pod. This module sets up a series of
// SPI transactions to the AD911x to configure it correctly for this
// project.
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

module syzygy_dac_controller (
	input  wire        clk,
	input  wire        reset,

	// Input to allow for a user-configurable amplitude
	// by setting the DAC FSADJ register
	input  wire [15:0] dac_fsadj,

	// Control signals for the DAC SPI interface
	output reg  [5:0]  spi_reg,
	output reg  [7:0]  spi_data_in,
	output reg         spi_send,
	input  wire        spi_done,
	output wire        spi_rw,

	output reg         dac_ready
	);

reg  [31:0] divide_counter;
reg         clk_en;
reg  [15:0] dac_fsadj_hold;

assign spi_rw = 1'b0;

reg [31:0] state;
localparam s_begin       = 0,
           s_ircml_start = 1,
           s_ircml_wait  = 2,
           s_qrcml_start = 3,
           s_qrcml_wait  = 4,
           s_irset_start = 5,
           s_irset_wait  = 6,
           s_qrset_start = 7,
           s_qrset_wait  = 8,
           s_end         = 9;

always @(posedge clk) begin
	if (reset == 1'b1) begin
		spi_reg     <= 6'h00;
		spi_data_in <= 8'h00;
		spi_send    <= 1'b0;
		dac_ready   <= 1'b0;

		state <= s_begin;
	end else begin
		spi_send  <= 1'b0;
		dac_ready <= 1'b0;

		case (state)
			s_begin: begin
				state <= s_ircml_start;
			end

			s_ircml_start: begin
				spi_send    <= 1'b1;
				spi_reg     <= 6'h05; // IRCML register address
				spi_data_in <= 8'h80; // Set to use internal 60 Ohm IRCML
				
				state <= s_ircml_wait;
			end

			s_ircml_wait: begin
				if (spi_done == 1'b1 && spi_send == 1'b0) begin
					state <= s_qrcml_start;
				end
			end

			s_qrcml_start: begin
				spi_send    <= 1'b1;
				spi_reg     <= 6'h08; // QRCML register address
				spi_data_in <= 8'h80; // Set to use internal 60 Ohm QRCML

				state <= s_qrcml_wait;
			end

			s_qrcml_wait: begin
				if(spi_done == 1'b1 && spi_send == 1'b0) begin
					state <= s_irset_start;
				end
			end
				
			s_irset_start: begin
				spi_send    <= 1'b1;
				spi_reg     <= 6'h04; // IRSET register address
				spi_data_in <= (8'h80 | dac_fsadj[5:0]); // Set to use internal FSADJ

				state <= s_irset_wait;
			end

			s_irset_wait: begin
				if(spi_done == 1'b1 && spi_send == 1'b0) begin
					state <= s_qrset_start;
				end
			end
				
			s_qrset_start: begin
				spi_send    <= 1'b1;
				spi_reg     <= 6'h07; // QRSET register address
				spi_data_in <= (8'h80 | dac_fsadj[13:8]); // Set to use internal FSADJ

				state <= s_qrset_wait;
			end
	
			s_qrset_wait: begin
				if(spi_done == 1'b1 && spi_send == 1'b0) begin
					state <= s_end;
				end
			end

			s_end: begin
				dac_ready <= 1'b1;
				
				if (dac_fsadj_hold != dac_fsadj) begin
					state <= s_irset_start;
					dac_fsadj_hold <= dac_fsadj;
				end
			end
		endcase
	end
end

endmodule
`default_nettype wire

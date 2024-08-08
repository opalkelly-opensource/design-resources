//-------------------------------------------------------------------------
// sync_trig.v
//
// This module can be used to synchronize "trigger" signals between clock
// domains. These triggers are assumed to be a single clock cycle pulse
// from the input, resulting in a single clock cycle pulse at the output.
//
// The frequency of input triggers must be less than half the output clock
// rate for the module to work properly and to synchronize all triggers as
// expected.
//
//-------------------------------------------------------------------------
// Copyright (c) 2022 Opal Kelly Incorporated
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
//-------------------------------------------------------------------------

`timescale 1ns/1ps

module sync_trig(
	input  wire  clk_i,
	input  wire  clk_o,
	input  wire  rst_i,
	input  wire  rst_o,
	input  wire  trig_i,
	output reg   trig_o
);

reg       cross_reg_i;
reg [1:0] cross_reg_o;

reg [6:0] state;
localparam state_a = 0,
           state_b = 1,
           state_c = 2;

always @(posedge clk_o) begin
	if(rst_o == 1'b1) begin
		cross_reg_o <= 2'b00;
	end else begin
		cross_reg_o[0] <= cross_reg_i;
		cross_reg_o[1] <= cross_reg_o[0];

		trig_o <= 1'b0;

		if(^cross_reg_o) begin
			trig_o <= 1'b1;
		end
	end
end


always @(posedge clk_i) begin
	if(rst_i == 1'b1) begin
		cross_reg_i <= 1'b0;
	end else begin
		if(trig_i == 1'b1) begin
			cross_reg_i <= ~cross_reg_i;
		end
	end
end
endmodule

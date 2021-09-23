//------------------------------------------------------------------------
// test_tf.v
//
// This testbench is provided to demonstrate usage of the sync_trig 
// module. This is not intended for verification purposes.
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
// 
//------------------------------------------------------------------------

`default_nettype none
`timescale 1ns / 1ps

module tf;
	reg          clk_src;
	reg          clk_dst;
	reg          reset_src;
	reg          reset_dst;
	reg          trig_src;
	wire         trig_dst;



//------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------
sync_trig dut (
		.clk_i        (clk_src),
		.clk_o        (clk_dst),
		.rst_i        (reset_src),
		.rst_o        (reset_dst),
		.trig_i       (trig_src),
		.trig_o       (trig_dst)
	);


// Clock Generation
parameter tCLK_src = 10;
parameter tCLK_dst = 7;
initial clk_src    = 0;
initial clk_dst    = 0;
always #(tCLK_src/2.0) clk_src = ~clk_src;
always #(tCLK_dst/2.0) clk_dst = ~clk_dst;



initial begin
	$dumpfile("dump.vcd"); $dumpvars;
	reset_src = 1'b1;
	reset_dst = 1'b0;
	trig_src  = 1'b0;
	#100;
	reset_src = 1'b0;
	#100;

	@(posedge clk_src);
	trig_src = 1'b1;
	#tCLK_src;
	trig_src = 1'b0;
	#100
	$finish;
end


endmodule

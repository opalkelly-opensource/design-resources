//------------------------------------------------------------------------
// test_tf.v
//
// This test fixture toggles the asynchronous reset line of the DUT
// twice, allowing the user to observe the synchronized output. This is 
// not intended for verification of the design.
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
	reg          clk;
	reg          reset_async;
	wire         reset_sync;



//------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------
sync_reset dut (
		.clk          (clk),
		.async_reset  (reset_async),
        .sync_reset   (reset_sync)
	);


// Clock Generation
parameter tCLK = 15;
initial clk    = 0;
always #(tCLK/2.0) clk = ~clk;



initial begin
	$dumpfile("dump.vcd"); $dumpvars;
	reset_async = 1'b1;
	#100;
	reset_async = 1'b0;
	#100;

	reset_async = 1'b1;
	#100;
	reset_async = 1'b0;
	#100;
	$finish;
end


endmodule

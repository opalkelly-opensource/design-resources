//------------------------------------------------------------------------
// test_tf.v
//
// This testbench is provided to demonstrate usage of the sync_bus module.
// The testbench is not intended as validation of the module.
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
	reg          reset;
	reg  [7:0]   bus_src;
	wire [7:0]   bus_dst;



//------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------
sync_bus # (
		.N                (8)
	) dut (
		.clk_src          (clk_src),
		.clk_dst          (clk_dst),
		.reset            (reset),
		.bus_src          (bus_src),
		.bus_dst          (bus_dst)
	);


// Clock Generation
parameter tCLK_SRC = 10;
parameter tCLK_DST = 23;
initial clk_src = 0;
initial clk_dst = 0;
always #(tCLK_SRC/2.0) clk_src = ~clk_src;
always #(tCLK_DST/2.0) clk_dst = ~clk_dst;



initial begin
	$dumpfile("dump.vcd"); $dumpvars;
	reset = 1'b1;
	bus_src = 8'h00;
	#100;
	reset = 1'b0;
	#100;

	bus_src = 8'h3A;
	#100;
	bus_src = 8'h57;
	#100;
	bus_src = 8'h95;
	#100;
	bus_src = 8'hb3;
	#100;
	$finish;
end


endmodule

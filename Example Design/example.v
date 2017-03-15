//------------------------------------------------------------------------
// example.v - Top-level instantiation of I2C Controller with FrontPanel
//
// Clocks:
//    CLK_SYS    - 100 MHz single-ended input clock
//    CLK_TI     - 48 MHz host-interface clock provided by okHost
//    CLK0       - Memory interface clock provided by MEM_IF
//    CLK_PIX    - 96 MHz single-ended input clock from image sensor
//
//
// Host Interface registers:
// WireIn 0x00
//     0 - Asynchronous reset
// WireIn 0x10
//   7:0 - I2C input data
//
// WireOut 0x30
//  15:0 - I2C data output
//
// TriggerIn 0x50
//     0 - I2C start
//     1 - I2C memory start
//     2 - I2C memory write
//     3 - I2C memory read
// TriggerOut 0x70  (i2c_clk)
//     0 - I2C done
//
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// Copyright (c) 2005-2017 Opal Kelly Incorporated
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
`timescale 1ns/1ps
`default_nettype none

module i2c_example (
	input  wire [7:0]  hi_in,
	output wire [1:0]  hi_out,
	inout  wire [15:0] hi_inout,
	inout  wire        hi_aa,
	output wire        hi_muxsel,
	output wire        gyro_cs,
	output wire        gyro_sa0,
	output wire        gyro_scl,
	inout  wire        gyro_sda
	);


// USB Host Interface
wire        clk_ti;
wire [30:0] ok1;
wire [16:0] ok2;

//OK
wire [15:0] ep00wire, ep10wire;
wire [15:0] ti50_clkti;
wire [15:0] to70_clkti;


assign hi_muxsel      = 1'b0;

assign gyro_cs        = 1'b1;  // Configure for I2C communication
assign gyro_sa0       = 1'b0;  // Gyro address will be 0xd0 (write), 0xd1 (read)

// Reset Chain
wire reset_syspll;
wire reset_pixdcm;
wire reset_async;
wire reset_clkpix;
wire reset_clkti;
wire reset_clk0;

assign reset_async         =  ep00wire[0];


// Create RESETs that deassert synchronous to specific clocks
sync_reset sync_reset2 (.clk(clk_ti),   .async_reset(reset_async),  .sync_reset(reset_clkti));



wire [15:0] memdin;
wire [7:0]  memdout;
i2cController # (
		.CLOCK_STRETCH_SUPPORT  (1),
		.CLOCK_DIVIDER          (480)
	) i2c_ctrl0 (
		.clk          (clk_ti),
		.reset        (reset_clkti),
		.start        (ti50_clkti[0]),
		.done         (to70_clkti[0]),
		.memclk       (clk_ti),
		.memstart     (ti50_clkti[1]),
		.memwrite     (ti50_clkti[2]),
		.memread      (ti50_clkti[3]),
		.memdin       (memdin[7:0]),
		.memdout      (memdout[7:0]),
		.i2c_sclk     (gyro_scl), 
		.i2c_sdat     (gyro_sda)
	);


// Instantiate the okHost and connect endpoints.
okHost host (
		.hi_in     (hi_in),
		.hi_out    (hi_out),
		.hi_inout  (hi_inout),
		.hi_aa     (hi_aa),
		.ti_clk    (clk_ti),
		.ok1       (ok1), 
		.ok2       (ok2)
	);

wire [17*2-1:0]  ok2x;
okWireOR # (.N(2)) wireOR (.ok2(ok2), .ok2s(ok2x));

okWireIn     wi00  (.ok1(ok1),                           .ep_addr(8'h00),                    .ep_dataout(ep00wire));
okWireIn     wi10  (.ok1(ok1),                           .ep_addr(8'h10),                    .ep_dataout(memdin));
okTriggerIn  ti50  (.ok1(ok1),                           .ep_addr(8'h50), .ep_clk(clk_ti),   .ep_trigger(ti50_clkti));
okTriggerOut to70  (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h70), .ep_clk(clk_ti),   .ep_trigger(to70_clkti));
okWireOut    wo30  (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'h30),                    .ep_datain({8'b0, memdout}));

endmodule

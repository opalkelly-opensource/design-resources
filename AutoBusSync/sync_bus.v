//------------------------------------------------------------------------
// SYNC_BUS
//
// Synchronizes an N-bit bus across a clock domain.
// This utilizes the handshake clock domain synchronization method where
// the destination is implemented as a register.
//
// This synchronizer is fully automatic and monitors changes on the 
// source bus to perform requests.
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
// 
//------------------------------------------------------------------------

`timescale 1ns/1ps

module sync_bus # (
		parameter N = 1
	) (
		input  wire          clk_src,
		input  wire [N-1:0]  bus_src,
		input  wire          reset,
		input  wire          clk_dst,
		output reg  [N-1:0]  bus_dst
 );


reg [N-1:0]  bus_src_hold;
reg          req_src;
reg          req_dst1, req_dst;
reg          ack_src1, ack_src;
reg          ack_dst;

always @(posedge reset or posedge clk_src) begin
	if (reset == 1'b1) begin
		req_src      <= 1'b0;
		ack_src      <= 1'b0;
		bus_src_hold <= 0;
	end else begin
		if (req_src == 1'b1) begin
			if (ack_src == 1'b1) begin
				req_src <= 1'b0;
			end
		end else begin
			if (ack_src == 1'b0) begin
				// If the source bus has changed, capture on the 
				// source clock and assert REQ.
				if (bus_src_hold != bus_src) begin
					bus_src_hold <= bus_src;
					req_src      <= 1'b1;
				end
			end
		end
	
		// Synchronize ACK to source domain.
		ack_src1 <= ack_dst;
		ack_src  <= ack_src1;
	end
end


always @(posedge clk_dst) begin
	// Synchronize REQ to destination domain.
	req_dst1 <= req_src;
	req_dst  <= req_dst1;
	
	// Upon request, capture the bus data then
	// send an ACK.
	if (req_dst == 1'b1) begin
		bus_dst <= bus_src_hold;
		ack_dst <= 1'b1;
	end
	
	// Clear REQ when the source clears REQ.
	if (req_dst == 1'b0) begin
		ack_dst <= 1'b0;
	end
end

endmodule

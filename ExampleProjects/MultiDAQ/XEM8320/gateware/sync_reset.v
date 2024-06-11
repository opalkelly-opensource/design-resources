//-------------------------------------------------------------------------
// sync_reset.v
//
// This is just a small module to synchronize the deassertion of an
// asynchronous reset to a clock.
//
// This module requires that the asynchronous reset be held for a minimum
// of one cycle of 'clk'.
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

module sync_reset(
    input  wire   clk,
    input  wire   async_reset,
    output wire   sync_reset
);


reg   async_d;
reg   async_dd;
always @(posedge clk) begin
    async_d  <= async_reset;
    async_dd <= async_d;
end

assign sync_reset = async_dd | async_reset;

endmodule
// 8-to-1 1-bit MUX
// 
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

`default_nettype none
module mux_8to1 (
	input  wire [7:0] datain,
	input  wire [2:0] sel,
	output reg        dataout
	);
	
always @(sel or datain) begin
	if      (sel == 3'b111) dataout = datain[7];
	else if (sel == 3'b110) dataout = datain[6];
	else if (sel == 3'b101) dataout = datain[5];
	else if (sel == 3'b100) dataout = datain[4];
	else if (sel == 3'b011) dataout = datain[3];
	else if (sel == 3'b010) dataout = datain[2];
	else if (sel == 3'b001) dataout = datain[1];
	else                    dataout = datain[0];
end

endmodule

`default_nettype wire
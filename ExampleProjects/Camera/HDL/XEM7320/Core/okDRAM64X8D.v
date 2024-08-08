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

module okDRAM64X8D(
	input  wire       wclk,
	input  wire       we,
	input  wire [5:0] addrA,
	input  wire [5:0] addrB,
	input  wire [7:0] din,
	output wire [7:0] doutA,
	output wire [7:0] doutB
	);

genvar i;
generate
for (i=0; i<8; i=i+1) begin : gen_ram
	RAM64X1D ram(.WCLK(wclk), .WE(we), .D(din[i]), .SPO(doutA[i]), .DPO(doutB[i]),
					 .A0(addrA[0]), .A1(addrA[1]), .A2(addrA[2]), .A3(addrA[3]), .A4(addrA[4]), .A5(addrA[5]),
					 .DPRA0(addrB[0]), .DPRA1(addrB[1]), .DPRA2(addrB[2]), .DPRA3(addrB[3]), .DPRA4(addrB[4]), .DPRA5(addrB[5]) );
end
endgenerate

endmodule
`default_nettype wire

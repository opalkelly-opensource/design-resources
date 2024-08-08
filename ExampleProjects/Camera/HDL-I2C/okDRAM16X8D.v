module okDRAM16X8D(
	input  wire       wclk,
	input  wire       we,
	input  wire [3:0] addrA,
	input  wire [3:0] addrB,
	input  wire [7:0] din,
	output wire [7:0] doutA,
	output wire [7:0] doutB
	);

genvar i;
generate
for (i=0; i<8; i=i+1) begin : gen_ram
	RAM16X1D ram(.WCLK(wclk), .WE(we), .D(din[i]), .SPO(doutA[i]), .DPO(doutB[i]),
					 .A0(addrA[0]), .A1(addrA[1]), .A2(addrA[2]), .A3(addrA[3]),
					 .DPRA0(addrB[0]), .DPRA1(addrB[1]), .DPRA2(addrB[2]), .DPRA3(addrB[3]) );
end
endgenerate

endmodule

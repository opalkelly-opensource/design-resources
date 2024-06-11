// SYNC_BUS
//
// Synchronizes an N-bit bus across a clock domain.
// This utilizes the handshake clock domain synchronization method where
// the destination is implemented as a register.
//
// This synchronizer is fully automatic and monitors changes on the 
// source bus to perform requests.
`default_nettype none
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
`default_nettype wire

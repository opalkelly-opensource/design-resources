//------------------------------------------------------------------------
// host_if.v
//
// Interface for reading frames from DDR
//
// Copyright (c) 2011 Opal Kelly Incorporated
//------------------------------------------------------------------------

`default_nettype none
`timescale 1ns / 1ps
module host_if(
	input  wire          clk,
	input  wire          clk_ti,
	input  wire          reset_clk,
	
	input  wire          readout_start,
	input  wire          readout_done,
	input  wire [29:0]   readout_addr,
	input  wire [23:0]   readout_count,

	output reg           mem_rd_req,
	output reg  [23:0]   mem_rd_addr,
	input  wire          mem_rd_ack,
	
	input  wire [63:0]   mem_rdata,
	input  wire          mem_rdata_valid,
	
	input  wire          ob_rd_en,
	output wire [10:0]   pofifo0_rd_count,  
	output wire [31:0]   pofifo0_dout,
	output wire          pofifo0_full,
	output wire          pofifo0_empty

	);


parameter IMAGE_COLUMNS    = 2592;
parameter IMAGE_ROWS       = 1944;

localparam BURST_LEN       = 4'd8;      // Number of 64bit user words per command
localparam BURST_LEN_BYTES = 8'd64;     // Number of bytes per command
localparam ADDRESS_INCREMENT   = 4'd8;


reg           ob_wr_en;
reg  [63:0]   ob_din;
wire [9:0]    ob_count;

reg  [23:0]   rd_byte_cnt;
reg           fifo_reset;


/////////////////////////////////
// DDR -> PipeOut Buffer
/////////////////////////////////
integer po_state;
localparam ps_idle  = 0,
           ps_read1 = 10,
           ps_read2 = 11;
always @(posedge clk or posedge reset_clk) begin
	if (reset_clk) begin
		po_state           <= ps_idle;
		mem_rd_req         <= 1'b0;
		rd_byte_cnt        <= 24'b0;
		ob_wr_en           <= 1'b0;
		ob_din             <= 64'h0;
		mem_rd_addr        <= 24'h0;
		fifo_reset         <= 1'b1;
	end else begin
		ob_wr_en      <= mem_rdata_valid;
		ob_din        <= mem_rdata;
		fifo_reset    <= 1'b0;
		mem_rd_req    <= 1'b0;
		
		if (readout_done) begin
			po_state <= ps_idle;
		end

		case (po_state)
			ps_idle: begin
				fifo_reset <= 1'b1;
				if (readout_start) begin
					mem_rd_addr        <= readout_addr[29:3];
					rd_byte_cnt        <= readout_count;
					po_state           <= ps_read1;
				end
			end

			ps_read1: begin
				// Only read from DDR when there is room in output buffer
				if (( (ob_count < 900 ) && (rd_byte_cnt>0)) && (mem_rd_ack == 1'b0) ) begin
					po_state          <= ps_read2;
				end
			end

			ps_read2: begin
				if (1'b1 == mem_rd_ack) begin
					rd_byte_cnt  <= rd_byte_cnt - BURST_LEN_BYTES;
					mem_rd_addr  <= mem_rd_addr + ADDRESS_INCREMENT;
					po_state     <= ps_read1;
				end else begin
					mem_rd_req        <= 1'b1;
				end
			end

		endcase
	end
end

// Pipeout FIFO
fifo_w64_1024_r32_2048 pofifo0_ (
	.aclr          (fifo_reset),
	.wrclk         (clk),
	.wrreq         (ob_wr_en),
	.data          ({ob_din[31:0], ob_din[63:32]}),           // Bus [63 : 0] 
	.wrusedw       (ob_count),         // Bus [9 : 0] 

	.rdclk         (clk_ti),
	.rdreq         (ob_rd_en),
	.q             ({pofifo0_dout[7:0], pofifo0_dout[15:8], pofifo0_dout[23:16], pofifo0_dout[31:24]}),     // Bus [31 : 0] 
	.rdusedw       (pofifo0_rd_count), // Bus [10 : 0] 

	.wrfull        (pofifo0_full),
	.rdempty       (pofifo0_empty)
	);
endmodule
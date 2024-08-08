//------------------------------------------------------------------------
// host_if.v
//
// Interface for reading frames from DDR
//
// Copyright (c) 2022 Opal Kelly Incorporated
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

	output reg           mem_rd_en,
	input  wire [63:0]   mem_rd_data,
	input  wire          mem_rd_empty,
	
	output reg           mem_cmd_en,
	output wire [2:0]    mem_cmd_instr,
	output reg  [29:0]   mem_cmd_byte_addr,
	output wire [5:0]    mem_cmd_burst_len, 
	
	input  wire          ob_rd_en,
	output wire [10:0]   pofifo0_rd_count,  
	output wire [15:0]   pofifo0_dout,
	output wire          pofifo0_full,
	output wire          pofifo0_empty

	);


parameter IMAGE_COLUMNS    = 2592;
parameter IMAGE_ROWS       = 1944;
localparam BURST_LEN       = 6'd32;     // Number of 64bit user words per command
localparam BURST_LEN_BYTES = 9'd256;    // Number of bytes per command


reg           ob_wr_en;
reg  [63:0]   ob_din;
wire [8:0]    ob_count;
reg  [29:0]   cmd_byte_addr_rd;
reg  [5:0]    rd_burst_cnt;
reg  [23:0]   rd_byte_cnt;
reg           fifo_reset;


assign mem_cmd_burst_len  = BURST_LEN - 1'b1;
assign mem_cmd_instr      = 3'b001;         // DDR Read Command


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
		mem_cmd_en         <= 1'b0;
		rd_byte_cnt        <= 24'b0;
		rd_burst_cnt       <= 6'd0;
		ob_wr_en           <= 1'b0;
		ob_din             <= 64'h0;
		cmd_byte_addr_rd   <= 30'b0;
		mem_cmd_byte_addr  <= 30'b0;
		fifo_reset         <= 1'b1;
	end else begin
		ob_wr_en      <= ~mem_rd_empty;
		ob_din        <= mem_rd_data;
		fifo_reset    <= 1'b0;
		mem_rd_en     <= 1'b1;
		mem_cmd_en    <= 1'b0;
		
		if (readout_done) begin
			po_state <= ps_idle;
		end

		case (po_state)
			ps_idle: begin
				fifo_reset <= 1'b1;
				if (readout_start) begin
					cmd_byte_addr_rd   <= readout_addr;
					rd_byte_cnt        <= readout_count;
					po_state           <= ps_read1;
				end
			end

			
			ps_read1: begin
				// Only read from DDR when there is room in output buffer
				if ((ob_count<440) && (rd_byte_cnt>0)) begin
					mem_cmd_en        <= 1'b1;
					mem_cmd_byte_addr <= cmd_byte_addr_rd;
					cmd_byte_addr_rd  <= cmd_byte_addr_rd + BURST_LEN_BYTES;
					rd_burst_cnt      <= BURST_LEN;
					po_state          <= ps_read2;
				end
			end

			
			ps_read2: begin
				if (rd_burst_cnt == 6'd0) begin
					po_state <= ps_read1;
				end else if (mem_rd_empty == 0) begin
					rd_byte_cnt  <= rd_byte_cnt - 4'd8;  // 8 bytes per 64-bit word
					rd_burst_cnt <= rd_burst_cnt - 1'b1;
				end
			end

		endcase
	end
end

// Pipeout FIFO
fifo_w64_512_r16_2048 pofifo0_ (
	.rst            (fifo_reset),
	.wr_clk         (clk),
	.wr_en          (ob_wr_en),
	.din            (ob_din),           // Bus [63 : 0] 
	.wr_data_count  (ob_count),         // Bus [8 : 0] 

	.rd_clk         (clk_ti),
	.rd_en          (ob_rd_en),
	.dout           ({pofifo0_dout[7:0], pofifo0_dout[15:8]}),     // Bus [15 : 0] 
	.rd_data_count  (pofifo0_rd_count), // Bus [10 : 0] 

	.full           (pofifo0_full),
	.empty          (pofifo0_empty),
	.valid          ()
	);
endmodule

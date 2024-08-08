//------------------------------------------------------------------------
// mem_arbiter.v
//
// Memory arbiter for the ZEM4310. Handles cordination of reads and writes to 
// Cyclone IV HPCII  DDR2 user interface.
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2009 Opal Kelly Incorporated
// $Rev: 1141 $ $Date: 2012-04-29 18:20:36 -0500 (Sun, 29 Apr 2012) $
//------------------------------------------------------------------------
`timescale 1ns/1ps
// Don't use this because the Xilinx MIG generates code that doesn't declare
// net types on module inputs, so it's not compliant.
//`default_nettype none

module mem_arbiter (
	// Clocks
	input  wire                                clk,
	input  wire                                reset,
	input  wire                                calib_done,
	
	// Interfaces
	input  wire                                hpc_ready,
	output reg                                 hpc_burstbegin,
	output wire [3:0]                          hpc_size,
	output reg  [23:0]                         hpc_address,
	
	output wire [7:0]                          hpc_be,
	output reg                                 hpc_write_req,
	output reg                                 hpc_read_req,
	
	input  wire                                rdata_valid,
	output reg                                 wdata_rd_en,
	
	// Arbiter requests and acknowledgements
	input  wire                                wr_req,
	output reg                                 wr_ack,
	input  wire [23:0]                         wr_addr,
	input  wire                                rd_req,
	output reg                                 rd_ack,
	input  wire [23:0]                         rd_addr
	);
	
localparam BURST_LEN       = 4'd8;      // Number of 64bit user words per command
localparam LAST_COMMAND_WAS_WRITE = 1'b0;
localparam LAST_COMMAND_WAS_READ = 1'b1;

	
// For a memory burst length 4 and half rate, the local burst length is 1.
assign hpc_size = BURST_LEN;
assign hpc_be   = 8'hff;

	reg last_command;
	reg [3:0] burst_cnt;
	
	integer state;
	localparam s_idle       = 0,
	           s_calib_wait = 1,
	           s_write_0    = 10,
	           s_write_1    = 11,
	           s_write_2    = 12,
	           s_write_3    = 13,
	           s_read_0     = 20,
	           s_read_1     = 21,
	           s_read_2     = 22;

	always @(posedge clk) begin
		if (reset) begin
			state             <= s_idle;
			hpc_burstbegin    <= 1'b0;
			hpc_address       <= 24'b0;
			last_command      <= 1'b0;
			wr_ack            <= 1'b0;
			rd_ack            <= 1'b0;
			wdata_rd_en       <= 1'b0;
			burst_cnt         <= 4'b000;
			hpc_read_req      <= 1'b0;
			hpc_write_req     <= 1'b0;
		end else begin
			wr_ack            <= 1'b0;
			rd_ack            <= 1'b0;
			hpc_burstbegin    <= 1'b0;
			wdata_rd_en       <= 1'b0;
			hpc_read_req      <= 1'b0;
			hpc_write_req     <= 1'b0;

			if (calib_done == 1'b0) begin
				state <= s_calib_wait;
			end
	
			case (state)
				s_calib_wait: begin
					if (calib_done == 1'b1) begin
						state <= s_idle;
					end
				end
				
				s_idle: begin
					burst_cnt <= BURST_LEN;
					
					if ((wr_req == 1'b1) && (rd_req == 1'b0)) begin
						hpc_address <= wr_addr;
						state <= s_write_0;
					end
					
					if ((wr_req == 1'b0) && (rd_req == 1'b1)) begin
						hpc_address <= rd_addr;
						state <= s_read_0;
					end
					
					// Collision.  Give the other request a turn.
					if ((wr_req == 1'b1) && (rd_req == 1'b1)) begin
						if (last_command == LAST_COMMAND_WAS_WRITE) begin
							hpc_address <= rd_addr;
							state <= s_read_0;
						end else begin
							hpc_address <= wr_addr;
							state <= s_write_0;
						end
					end
				end
				
			
				s_write_0: begin
					if (hpc_ready == 1'b1) begin
						wdata_rd_en <= 1'b1;
						burst_cnt <= burst_cnt - 1'b1;
						state <= s_write_1;
					end
				end
	
				s_write_1: begin
					last_command <= LAST_COMMAND_WAS_WRITE;
					if (hpc_ready == 1'b1) begin
						hpc_burstbegin <= 1'b1;
						hpc_write_req <= 1'b1;
						wdata_rd_en <= 1'b1;
						burst_cnt <= burst_cnt - 1'b1;
						state <= s_write_2;
					end
				end
			
				s_write_2: begin
					hpc_write_req <= 1'b1;
					// Keep write request and data present until
					// controller is ready.
					if (hpc_ready == 1'b1) begin
						if (burst_cnt == 3'd0) begin
							state  <= s_write_3;
						end else begin
							wdata_rd_en <= 1'b1;
							burst_cnt <= burst_cnt - 1'b1;
						end
					end
				end
				
				s_write_3: begin
					wr_ack <= 1'b1;
					if (wr_req == 1'b0) begin
						state <= s_idle;
					end
				end
	
				s_read_0: begin
					if (hpc_ready == 1'b1) begin 
						last_command    <= LAST_COMMAND_WAS_READ;
						hpc_burstbegin  <= 1'b1;
						hpc_read_req    <= 1'b1;
						state           <= s_read_1;
					end
				end
				
				s_read_1: begin
					if (hpc_ready == 1'b1) begin 
						state           <= s_read_2;
					end else begin
						hpc_read_req    <= 1'b1;
					end
				end
				
				s_read_2: begin
					rd_ack <= 1'b1;
					if (rd_req == 1'b0) begin
						state <= s_idle;
					end
				end

			endcase
		end
	end


endmodule

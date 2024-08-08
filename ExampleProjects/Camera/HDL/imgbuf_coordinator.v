//------------------------------------------------------------------------
// imgbuf_coordinator.v
//
// The coordinator handles the exchange of image buffers between the input
// path from the image sensor to the DRAM and the output path from the
// DRAM to the output pipe. Each image buffer is handled as an address
// pointing to the location of the beginning of the buffer in DRAM.
// 
// Each buffer, once filled by the image sensor, is pushed onto a FIFO to
// make it available for the output path.
//
// The input path state machine first generates a new buffer address by
// adding the total image size in bytes to the current address. This is
// then compared to the output buffer address. If the addresses are found
// to match, or if the FIFO is full, the input buffer must pull its next
// address from the FIFO rather than use the generated address. This
// prevents writing to a full FIFO and writing to a location in use by the
// output buffer. When this occurs the output buffer is considered
// "behind", and subsequent addresses will also be pulled from the FIFO
// until the output buffer is caught up (pulling it's own addresses from
// the FIFO). Once it has an address, the input path state machine
// triggers the image sensor state machine to fill the buffer. Once full,
// the address for the buffer is pushed to the top of the FIFO, and the
// state machine begins again.
//
// The output path state machine waits for a trigger from the software.
// Once triggered, the output path waits for the input path to determine
// its address if it is in that state. This prevents both paths reading
// the same address from the FIFO. Once complete, the output path pulls
// its next address from the FIFO and updates its "behind" signal to
// indicate that it is caught up to the current state of the FIFO. It then
// triggers the host interface state machine used to pull data from the 
// buffer to a PipeOut endpoint. Once full, the output path state machine
// returns to idle.
//
// From the software point of view, polling of the FIFO empty signal will
// indicate if a buffer is available for the output path.
// 
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2022 Opal Kelly Incorporated
// $Rev:$ $Date:$
//------------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module imgbuf_coordinator # (
	parameter TOTAL_MEM                 = 536870912,
	parameter ADDR_FIFO_PROG_FULL_MAX   = 1023,
	parameter ADDR_FIFO_PROG_FULL_MIN   = 4,
	parameter ADDR_FIFO_PROG_EMPTY_MAX  = 1023,
	parameter ADDR_FIFO_PROG_EMPTY_MIN  = 6
) (
	input  wire        clk,
	input  wire        rst,
	output reg  [15:0] missed_count,
	output reg         imgif_trig,
	input  wire        imgctl_framedone,
	input  wire        imgctl_framewritten,
	output reg  [29:0] input_buffer_addr,
	output reg  [29:0] output_buffer_addr,
	input  wire [23:0] img_size,
	input  wire        output_buffer_trig,
	output reg         output_buffer_start,
	input  wire        output_buffer_done,
	output reg         output_buffer_behind,
	output wire [10:0] buff_addr_fifo_count,
	input  wire  [9:0] buff_addr_prog_empty_setpt,
	input  wire  [9:0] buff_addr_prog_full_setpt,
	output wire        buff_addr_fifo_empty_comb,
	output wire        buff_addr_fifo_full_comb,
	input  wire        use_prog_empty,
	input  wire        use_prog_full,
	input  wire        memif_calib_done
	);

reg  [29:0] input_buffer_addr_next;
wire [29:0] output_buffer_addr_next;
reg         buff_fifo_wr;
reg         buff_fifo_rd;
wire        buff_addr_fifo_empty;
wire        buff_addr_fifo_full;
wire        buff_addr_prog_empty;
wire        buff_addr_prog_full;
reg  [9:0]  buff_addr_prog_empty_thresh;
reg  [9:0]  buff_addr_prog_full_thresh;
reg  [7:0]  reset_cnt;

assign buff_addr_fifo_empty_comb = (use_prog_empty == 1'b1) ? buff_addr_prog_empty | buff_addr_fifo_empty : buff_addr_fifo_empty;
assign buff_addr_fifo_full_comb = (use_prog_full == 1'b1) ? buff_addr_prog_full | buff_addr_fifo_full : buff_addr_fifo_full;

reg [5:0] input_buffer_state;
localparam ib_s_reset       = 0,
           ib_s_idle        = 1,
           ib_s_check_addr  = 2,
           ib_s_fill_buffer = 3,
           ib_s_waitframe   = 4,
           ib_s_finish      = 5;

reg [5:0] output_buffer_state;
localparam ob_s_idle    = 0,
           ob_s_wait    = 1,
           ob_s_readout = 2,
           ob_s_finish  = 3;

always @(posedge clk) begin
	if (rst) begin
		input_buffer_state <= ib_s_reset;
		input_buffer_addr  <= 30'h0;
		input_buffer_addr_next <= 30'h0;
		output_buffer_state <= ob_s_idle;
		output_buffer_addr <= 30'h0;
		output_buffer_start <= 1'b0;
		buff_fifo_wr <= 1'b0;
		buff_fifo_rd <= 1'b0;
		imgif_trig <= 1'b0;
		missed_count <= 16'b0;
		output_buffer_behind <= 1'b0;
		buff_addr_prog_full_thresh <= 10'd0;
		buff_addr_prog_empty_thresh <= 10'd0;
		reset_cnt <= 8'hFF;
	end else begin
		buff_fifo_wr <= 1'b0;
		buff_fifo_rd <= 1'b0;
		imgif_trig <= 1'b0;
		output_buffer_start <= 1'b0;
		
		// Input buffer handling
		case (input_buffer_state)
			// Wait for calibration to complete and give some time for everything to settle
			ib_s_reset: begin
				if(memif_calib_done == 1'b1) begin
					if(reset_cnt == 8'h00) begin
						input_buffer_state <= ib_s_idle;
					end else begin
						reset_cnt <= reset_cnt - 8'h1;
					end
				end
			end
		
			ib_s_idle: begin
				// Generate the next buffer address
				if(input_buffer_addr < (TOTAL_MEM - (img_size << 1))) begin
					input_buffer_addr_next <= input_buffer_addr + (img_size);
				end else begin
					input_buffer_addr_next <= 32'd0;
				end
				
				input_buffer_state <= ib_s_check_addr;
				reset_cnt <= 8'h01;
			end
			
			ib_s_check_addr: begin
				// If the next image buffer to be used as a capture buffer (and
				// subsequently queued into the FIFO) is presently locked for
				// readout, we need to skip it and use the image buffer
				// following it.
				if ((~buff_addr_fifo_empty_comb) 
				    && ((input_buffer_addr_next == output_buffer_addr)
				    || (input_buffer_addr_next == output_buffer_addr_next)
				    || (buff_addr_fifo_full_comb == 1'b1))) begin
					buff_fifo_rd <= 1'b1;
					input_buffer_addr <= output_buffer_addr_next[29:0];
					missed_count <= missed_count + 1'b1;
					output_buffer_behind <= 1'b1;
				end else begin
					input_buffer_addr <= input_buffer_addr_next;
				end
				
				input_buffer_state <= ib_s_fill_buffer;
				reset_cnt <= 8'h02;
			end
			
			ib_s_fill_buffer: begin
				imgif_trig <= 1'b1;
				input_buffer_state <= ib_s_finish;
				reset_cnt <= 8'h03;
			end
			
			ib_s_waitframe: begin
				if (imgctl_framedone == 1'b1) begin
					input_buffer_state <= ib_s_finish;
				end
				reset_cnt <= 8'h04;
			end
			
			// Once the buffer is full, push its address onto the FIFO
			// to indicate that it's ready for reading
			ib_s_finish: begin
				if (imgctl_framewritten == 1'b1) begin
					buff_fifo_wr <= 1'b1;
					input_buffer_state <= ib_s_idle;
				end
				reset_cnt <= 8'h05;
			end
		endcase
		
		case (output_buffer_state)
			// Wait for a signal from the software to continue
			ob_s_idle: begin
				if(output_buffer_trig && ~buff_addr_fifo_empty) begin
					output_buffer_state <= ob_s_wait;
				end
			end
			
			ob_s_wait: begin
				// Wait for the input buffer to determine its addres, this prevents both buffers
				// obtaining the same address, leading to tearing.
				if((input_buffer_state != ib_s_check_addr)) begin
					buff_fifo_rd <= 1'b1;
					output_buffer_addr <= output_buffer_addr_next[29:0];
					output_buffer_state <= ob_s_readout;
					output_buffer_behind <= 1'b0;
					missed_count <= 16'b0;
				end
			end
			
			ob_s_readout: begin
				output_buffer_start <= 1'b1;
				output_buffer_state <= ob_s_finish;
			end
			
			ob_s_finish: begin
				if(output_buffer_done == 1'b1) begin
					output_buffer_state <= ob_s_idle;
				end
			end
		endcase
		
		if (use_prog_full == 1'b1) begin
			buff_addr_prog_full_thresh <= buff_addr_prog_full_setpt;
		end else begin
			buff_addr_prog_full_thresh <= ADDR_FIFO_PROG_FULL_MAX;
		end
		
		if (use_prog_empty == 1'b1) begin
			buff_addr_prog_empty_thresh <= buff_addr_prog_empty_setpt;
		end else begin
			buff_addr_prog_empty_thresh <= ADDR_FIFO_PROG_EMPTY_MIN;
		end
	end
end

buff_addr_fifo buff_addr_fifo_inst (
  .clk(clk),                                       // input wire clk
  .srst(rst),                                      // input wire srst
  .din({2'b0, input_buffer_addr}),                 // input wire [31 : 0] din
  .wr_en(buff_fifo_wr),                            // input wire wr_en
  .rd_en(buff_fifo_rd),                            // input wire rd_en
  .prog_empty_thresh(buff_addr_prog_empty_thresh), // input wire [9 : 0] prog_empty_thresh
  .prog_full_thresh(buff_addr_prog_full_thresh),   // input wire [9 : 0] prog_full_thresh
  .dout(output_buffer_addr_next),                  // output wire [31 : 0] dout
  .full(buff_addr_fifo_full),                      // output wire full
  .empty(buff_addr_fifo_empty),                    // output wire empty
  .data_count(buff_addr_fifo_count),               // output wire [6 : 0] data_count
  .prog_full(buff_addr_prog_full),                 // output wire prog_full
  .prog_empty(buff_addr_prog_empty)                // output wire prog_empty
);

endmodule
`default_nettype wire // set the default_nettype back to wire as Xilinx IPs depend on this

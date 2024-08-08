//------------------------------------------------------------------------
// image_if.v
//
// This block operates at the pixel clock and receives pixel data and
// timing from the image sensor.  From an external trigger toggle, an
// image capture is initiated.  The image data is stored to memory using
// an available memory write port.
//
// TRIGGER      - This is a trigger input initiates a capture.
// START_ADDR   - The start address for storing the next frame.
// FRAME_DONE   - Asserted at completion of a stored frame.
// PACKING_MODE - Determines the pixel packing to memory:
//                0 - 8-bit pixels, lower four bits truncated
//                1 - 16-bit pixels, upper four bits padded with 0
//
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2022 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------

`default_nettype none
`timescale 1ns / 1ps
module image_if(
	input  wire          clk,
	input  wire          reset,
	input  wire          packing_mode,

	input  wire          pix_fv,
	input  wire          pix_lv,
	input  wire [11:0]   pix_data,
	
	input  wire          trigger,
	input  wire [29:0]   start_addr,
	output reg           frame_done,
	output reg           skipped,
	
	//MIG Write Interface
	output reg           mem_wr_en,
	output reg  [63:0]   mem_wr_data,
	output wire [7:0]    mem_wr_mask,
	output reg           mem_cmd_en,
	output wire [2:0]    mem_cmd_instr,
	output reg  [29:0]   mem_cmd_byte_addr,
	output wire [5:0]    mem_cmd_burst_len
	);

localparam BURST_LEN       = 6'd32;     // Number of 64bit user words per command
localparam BURST_LEN_BYTES = 9'd256;    // Number of bytes per command


(* IOB = "true" *)
reg          reg_fv;
(* IOB = "true" *)
reg          reg_lv;
(* IOB = "true" *)
reg  [11:0]  reg_pixdata;

reg          reg_fv1;
reg          reg_packing_mode;
reg  [29:0]  cmd_byte_addr_wr;
reg  [6:0]   write_cnt;
reg  [2:0]   pixel_index;

reg  [10:0]  row_count; /*synthesis keep*/
reg  [11:0]  col_count; /*synthesis keep*/


assign mem_cmd_burst_len  = BURST_LEN - 1'b1;
assign mem_wr_mask        = 8'b00000000;    // Write all bytes
assign mem_cmd_instr      = 3'b000;         // DDR Write Command


always @(posedge clk) begin
	reg_fv      <= pix_fv;
	reg_fv1     <= reg_fv;
	reg_lv      <= pix_lv;
	reg_pixdata <= pix_data;
end


integer state;
localparam s_idle             = 0,
           s_framewait        = 1,
           s_framestore_8bpp  = 2,
           s_framestore_16bpp = 3,
           s_flush1           = 4,
           s_flush2           = 5;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		mem_cmd_en        <= 1'b0;
		mem_wr_en         <= 1'b0;
		mem_wr_data       <= 64'h0;
		mem_cmd_byte_addr <= 30'h0;
		cmd_byte_addr_wr  <= 30'h0;
		write_cnt         <= 7'b0;
		frame_done        <= 1'b0;
		skipped           <= 1'b0;
		pixel_index       <= 3'b0;
		state             <= s_idle;
	end else begin
		mem_cmd_en  <= 1'b0;
		mem_wr_en   <= 1'b0;
		frame_done  <= 1'b0;
		skipped     <= 1'b0;
		
		case (state)
			s_idle: begin
				if (trigger) begin
					state <= s_framewait;
					reg_packing_mode <= packing_mode;
				end
				
				// Signal a skipped frame if we see a frame valid come by
				// in the idle state.
				if ({reg_fv1, reg_fv} == 2'b01) begin
					skipped <= 1'b1;
				end
			end
			
			//
			// Once triggered, we wait here for the start of a frame.
			//
			s_framewait: begin
				pixel_index <= 3'b0;
				write_cnt   <= 7'b0;
				if (reg_fv == 1'b0) begin
					state <= (reg_packing_mode) ? (s_framestore_16bpp) : (s_framestore_8bpp);
					cmd_byte_addr_wr <= start_addr;
				end
			end
			
			
			// At the end of a frame, force a burst write to memory to clear
			// out the MIG write FIFO.
			s_flush1: begin
				state             <= s_flush2;
				mem_cmd_en        <= 1'b1;
				mem_cmd_byte_addr <= cmd_byte_addr_wr;
			end
			s_flush2: begin
				state             <= s_idle;
				mem_cmd_en        <= 1'b1;
				mem_cmd_byte_addr <= cmd_byte_addr_wr;
			end
			
			
			//
			// After a new frame starts, store pixel data when LV is asserted.
			// 8BPP - 8 bits per pixel with LSBs thrown out.
			// Shortened pixel data, but good bandwidth.
			//
			s_framestore_8bpp: begin
				if ({reg_fv1, reg_fv} == 2'b10) begin
					frame_done <= 1'b1;
					state      <= s_flush1;
				end
				
				if (reg_lv) begin
					pixel_index <= pixel_index + 1'b1;
					
					case (pixel_index)
						3'd0: mem_wr_data[63:56] <= reg_pixdata[11:4];
						3'd1: mem_wr_data[55:48] <= reg_pixdata[11:4];
						3'd2: mem_wr_data[47:40] <= reg_pixdata[11:4];
						3'd3: mem_wr_data[39:32] <= reg_pixdata[11:4];
						3'd4: mem_wr_data[31:24] <= reg_pixdata[11:4];
						3'd5: mem_wr_data[23:16] <= reg_pixdata[11:4];
						3'd6: mem_wr_data[15:8]  <= reg_pixdata[11:4];
						3'd7: begin
							mem_wr_data[7:0] <= reg_pixdata[11:4]; 
							mem_wr_en        <= 1'b1;
							
							if (write_cnt < BURST_LEN-1) begin
								write_cnt <= write_cnt + 1'b1;
							end else begin
								// DDR write command
								write_cnt         <= 7'b0;
								mem_cmd_en        <= 1'b1;
								mem_cmd_byte_addr <= cmd_byte_addr_wr;
								cmd_byte_addr_wr  <= cmd_byte_addr_wr + BURST_LEN_BYTES; 
							end
						end
					endcase
				end
			end


			//
			// After a new frame starts, store pixel data when LV is asserted.
			// 16BPP - 16 bits per pixel with each pixel padded with 4-bits of 0.
			// Full pixel data, but wasteful of bandwidth.
			//
			s_framestore_16bpp: begin
				if ({reg_fv1, reg_fv} == 2'b10) begin
					frame_done <= 1'b1;
					state      <= s_flush1;
				end
				
				if (reg_lv) begin
					pixel_index <= pixel_index + 1'b1;
					
					case (pixel_index[1:0])
						2'd0: mem_wr_data[63:48] <= {4'b0, reg_pixdata};
						2'd1: mem_wr_data[47:32] <= {4'b0, reg_pixdata};
						2'd2: mem_wr_data[31:16] <= {4'b0, reg_pixdata};
						2'd3: begin
							mem_wr_data[15:0] <= {4'b0, reg_pixdata}; 
							mem_wr_en         <= 1'b1;
							
							if (write_cnt < BURST_LEN-1) begin
								write_cnt <= write_cnt + 1'b1;
							end else begin
								// DDR write command
								write_cnt         <= 7'b0;
								mem_cmd_en        <= 1'b1;
								mem_cmd_byte_addr <= cmd_byte_addr_wr;
								cmd_byte_addr_wr  <= cmd_byte_addr_wr + BURST_LEN_BYTES; 
							end
						end
					endcase
				end
			end
		endcase

	end
end

endmodule

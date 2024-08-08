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
// Copyright (c) 2005-2011 Opal Kelly Incorporated
// $Rev: 1141 $ $Date: 2012-04-29 18:20:36 -0500 (Sun, 29 Apr 2012) $
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
	input  wire          mem_clk,
	input  wire          mem_reset,
	
	output reg           mem_wr_req,
	output reg   [23:0]  mem_wr_addr,
	input  wire          mem_wr_ack,
	
	input  wire          mem_wdata_rd_en,
	output wire  [63:0]  mem_wdata,
	output wire          fifo_full,
	output wire          fifo_empty
	);

localparam BURST_LEN = 4'd8;
localparam ADDRESS_INCREMENT   = 5'd8; // UI Address is a user interface address.

reg          reg_fv;
reg          reg_lv;
reg  [11:0]  reg_pixdata;

reg          reg_fv1;
reg          reg_packing_mode;
reg  [2:0]   pixel_index;

reg          fifo_wren;
reg  [63:0]  fifo_din;
reg          fifo_reset;
//wire         fifo_full;
//wire         fifo_empty;
wire [9:0]   fifo_rd_data_count;
wire [9:0]   fifo_wr_data_count;

reg          regm_fv;
reg          regm_fv1;
reg          trigger_hpc;
reg          reg_trigger_hpc;


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
           s_framestore_16bpp = 3;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		fifo_wren         <= 1'b0;
		fifo_din          <= 64'h0;
		frame_done        <= 1'b0;
		trigger_hpc       <= 1'b0;
		skipped           <= 1'b0;
		pixel_index       <= 3'b0;
		state             <= s_idle;
	end else begin
		fifo_wren   <= 1'b0;
		skipped     <= 1'b0;
		frame_done  <= 1'b0;
		
		case (state)
			s_idle: begin
				trigger_hpc <= 1'b0;
				if (trigger) begin
					state <= s_framewait;
					trigger_hpc <= 1'b1;
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
				if (reg_fv == 1'b0) begin
					state <= (reg_packing_mode) ? (s_framestore_16bpp) : (s_framestore_8bpp);
				end
			end
			
			
			//
			// After a new frame starts, store pixel data when LV is asserted.
			// 8BPP - 8 bits per pixel with LSBs thrown out.
			// Shortened pixel data, but good bandwidth.
			//
			s_framestore_8bpp: begin
				if ({reg_fv1, reg_fv} == 2'b10) begin
					frame_done <= 1'b1;
					state <= s_idle;
				end
				
				if (reg_lv) begin
					pixel_index <= pixel_index + 1'b1;
					
					case (pixel_index)
						3'd0: fifo_din[63:56] <= reg_pixdata[11:4];
						3'd1: fifo_din[55:48] <= reg_pixdata[11:4];
						3'd2: fifo_din[47:40] <= reg_pixdata[11:4];
						3'd3: fifo_din[39:32] <= reg_pixdata[11:4];
						3'd4: fifo_din[31:24] <= reg_pixdata[11:4];
						3'd5: fifo_din[23:16] <= reg_pixdata[11:4];
						3'd6: fifo_din[15:8]  <= reg_pixdata[11:4];
						3'd7: begin
							fifo_din[7:0] <= reg_pixdata[11:4]; 
							fifo_wren        <= 1'b1;
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
					state <= s_idle;
				end
				
				if (reg_lv) begin
					pixel_index <= pixel_index + 1'b1;
					
					case (pixel_index[1:0])
						2'd0: fifo_din[63:48] <= {4'b0, reg_pixdata};
						2'd1: fifo_din[47:32] <= {4'b0, reg_pixdata};
						2'd2: fifo_din[31:16] <= {4'b0, reg_pixdata};
						2'd3: begin
							fifo_din[15:0] <= {4'b0, reg_pixdata}; 
							fifo_wren         <= 1'b1;
						end
					endcase
				end
			end
		endcase

	end
end

////////////////////////////////
// Pixel Buffer -> DDR
/////////////////////////////////
integer pixbuf_state;
localparam ps_idle   = 0,
           ps_open   = 1,
           ps_write1 = 10,
           ps_write2 = 11,
           ps_flush1  = 31,
           ps_flush2  = 32,
           ps_flush3  = 33;
 always @(posedge mem_clk) begin
	regm_fv      <= pix_fv;
	regm_fv1     <= regm_fv;
end

always @(posedge mem_clk or posedge mem_reset) begin
	if (mem_reset) begin
		pixbuf_state      <= ps_idle;
		mem_wr_req        <= 1'b0;
		mem_wr_addr       <= 24'h0;
		fifo_reset        <= 1'b1;
	end else begin
		mem_wr_req  <= 1'b0;
		reg_trigger_hpc <= trigger_hpc;
		fifo_reset        <= 1'b0;

		case (pixbuf_state)
			ps_idle: begin //0
				fifo_reset <= 1'b1;
				if (1'b1 == reg_trigger_hpc) begin
					mem_wr_addr  <= start_addr[29:3];
					pixbuf_state      <= ps_write1;
					//pixbuf_state      <= ps_open;
				end
			end
			
			ps_open: begin //31
				if (mem_wr_ack == 1'b1) begin
					pixbuf_state      <= ps_write1;
				end else begin
					mem_wr_req        <= 1'b1;
				end
			end

			ps_write1: begin //10
				if ({regm_fv1, regm_fv} == 2'b10) begin
					pixbuf_state      <= ps_flush1;
				end
				
				if ((fifo_rd_data_count >= BURST_LEN) && (mem_wr_ack == 1'b0) ) begin
					// DDR write request
						pixbuf_state      <= ps_write2;
				end
			end
			
			ps_write2: begin //11
				if (mem_wr_ack == 1'b1) begin
					mem_wr_addr       <= mem_wr_addr + ADDRESS_INCREMENT;
					pixbuf_state      <= ps_write1;
				end else begin
					mem_wr_req        <= 1'b1;
				end
			end
			

			// At the end of a frame, force a burst write to memory to clear
			// out the MIG write FIFO.
			ps_flush1: begin //31
				if (fifo_empty == 1'b0) begin
					if (mem_wr_ack == 1'b0) begin
						pixbuf_state      <= ps_flush2;
					end
				end else begin
					pixbuf_state      <= ps_idle;
				end
			end
			
			ps_flush2: begin //33
				if (mem_wr_ack == 1'b1) begin
					mem_wr_addr       <= mem_wr_addr + ADDRESS_INCREMENT;
					pixbuf_state      <= ps_flush1;
				end else begin
					mem_wr_req        <= 1'b1;
				end
			end



		endcase
	end
end


// Pixel CLock to MIG Clock CDC
fifo_w64_1024_r64_1024 pixelfifo0 (
	.aclr      (fifo_reset),
	.wrclk     (clk),
	.rdclk     (mem_clk),
	.data      (fifo_din),
	.wrreq     (fifo_wren),
	.rdreq     (mem_wdata_rd_en),
	.q         (mem_wdata),
	.wrfull    (fifo_full),
	.rdempty   (fifo_empty),
	.rdusedw   (fifo_rd_data_count),
	.wrusedw   (fifo_wr_data_count)
);

endmodule

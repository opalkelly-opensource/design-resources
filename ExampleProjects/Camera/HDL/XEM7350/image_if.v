//------------------------------------------------------------------------
// image_if.v
//
// This block operates at the pixel clock and receives pixel data and
// timing from the image sensor.  From an external trigger toggle, an
// image capture is initiated.  The image data is stored to memory using
// an available memory write port.
//
// TRIGGER       - This is a trigger input initiates a capture.
// START_ADDR    - The start address for storing the next frame.
// FRAME_DONE    - Asserted at completion of a stored frame.
// FRAME_WRITTEN - Asserted after a frame has been written to memory
// PACKING_MODE  - Determines the pixel packing to memory:
//                 0 - 8-bit pixels, lower four bits truncated
//                 1 - 16-bit pixels, upper four bits padded with 0
//
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2011 Opal Kelly Incorporated
// $Rev: 1141 $ $Date: 2012-04-29 18:20:36 -0500 (Sun, 29 Apr 2012) $
//------------------------------------------------------------------------
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
	output reg           frame_written,
	output reg           skipped,
	
	//MIG Write Interface
	input  wire          mem_clk,
	input  wire          mem_reset,
	
	output reg           mem_wr_req,
	output reg   [28:0]  mem_wr_addr,
	input  wire          mem_wr_ack,
	
	output wire  [8:0]   fifo_rd_data_count,
	input  wire          mem_wdata_rd_en,
	output wire [127:0]  mem_wdf_data,
	output wire          fifo_full,
	output wire          fifo_empty
	);

localparam BURST_LEN = 6'd1;  //(WORD_SIZE*BURST_MODE/UI_SIZE) = BURST_UI_WORD_COUNT : 16*8/128 = 1
localparam ADDRESS_INCREMENT   = 5'd8; // UI Address is a word address. BL8 Burst Mode = 8.  Memory Width = 16

(* IOB = "true" *)
reg          reg_fv;
(* IOB = "true" *)
reg          reg_lv;
(* IOB = "true" *)
reg  [11:0]  reg_pixdata;

reg          reg_fv1;
reg          reg_packing_mode;
reg  [2:0]   pixel_index;

reg          fifo_wren;
reg  [63:0]  fifo_din;
reg          fifo_reset;

reg          enable_pix;
reg          enable_mig, enable_mig_reg;
reg          ready_mig, ready_mig_reg;

reg  [28:0]  cmd_start_address;

reg          regm_fv;
reg          regm_fv1;


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
		enable_mig        <= 1'b0;
		enable_pix        <= 1'b0;
		skipped           <= 1'b0;
		pixel_index       <= 3'b0;
		state             <= s_idle;
		reg_packing_mode  <= 1'b0;
		ready_mig_reg     <= 1'b0;
	end else begin
		fifo_wren     <= 1'b0;
		skipped       <= 1'b0;
		frame_done    <= 1'b0;
		ready_mig_reg <= ready_mig;
		
		// Handshake with MIG Write Process
		
		case (state)
			s_idle: begin
				enable_mig <= 1'b0;
				
				// Catch the trigger if it occurs and the MIG side of things
				// is not yet ready, we'll stay in idle to catch any skipped
				// frames as they come by. This is mostly precautionary.
				if (trigger) begin
					enable_pix = 1'b1;
				end

				if (enable_pix && ready_mig_reg) begin
					enable_pix <= 1'b0;
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
				if (reg_fv == 1'b0) begin
					state <= (reg_packing_mode) ? (s_framestore_16bpp) : (s_framestore_8bpp);
					enable_mig <= 1'b1;
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
           WaitReset = 1,
           ps_write1 = 10,
           ps_write2 = 11,
           ps_flush1  = 31,
           ps_flush2  = 32;
           
wire       wr_rst_busy;
wire       rd_rst_busy;
reg  [3:0] resetCount;  
always @(posedge mem_clk) begin
	regm_fv      <= pix_fv;
	regm_fv1     <= regm_fv;
end

always @(posedge mem_clk or posedge mem_reset) begin
	if (mem_reset) begin
		pixbuf_state      <= WaitReset;
		mem_wr_req        <= 1'b0;
		mem_wr_addr       <= 29'h0;
		fifo_reset        <= 1'b1;
		cmd_start_address <= 29'h0;
		frame_written     <= 1'b0;
		enable_mig_reg    <= 1'b0;
		ready_mig         <= 1'b0;
		resetCount        <= 4'h0;
	end else begin
		mem_wr_req        <= 1'b0;
		enable_mig_reg    <= enable_mig;
		cmd_start_address <= start_addr[29:1];
		fifo_reset        <= 1'b0;
		frame_written     <= 1'b0;
		ready_mig         <= 1'b0;

		case (pixbuf_state)
            // To reset the independent clock fifo we must asset reset for
            // a recommended 3 clock cycles of the slowest clock.
            // rd_clk = mem_clk = 100MHz
            // wr_clk = clk = clk_pix = 96 MHz
            // At least 4 mem_clk cycles are required.
            // See PG057 for more information.
            WaitReset: begin
                if (resetCount < 4'd4) begin
                    fifo_reset         <= 1'b1;
                    resetCount         <= resetCount + 1'b1;
                end else begin
                    if(!wr_rst_busy && !rd_rst_busy) begin
                        pixbuf_state       <= ps_idle;
                    end
                end
            end
			ps_idle: begin
				ready_mig  <= 1'b1;
				if (1'b1 == enable_mig_reg && regm_fv1 == 1'b1) begin
					mem_wr_addr  <= cmd_start_address;
					pixbuf_state      <= ps_write1;
				end
			end
			
			//
			// Signal the memory controller to write bursts of image data to the memory
			// when enough data is built up in the FIFO.
			// 
			ps_write1: begin
				if (regm_fv1 == 1'b0 && fifo_empty) begin
					pixbuf_state <= ps_flush1;
				end
				
				if ((fifo_rd_data_count >= BURST_LEN) && (mem_wr_ack == 1'b0) ) begin
					// DDR write request
					pixbuf_state      <= ps_write2;
					mem_wr_req        <= 1'b1;
				end
			end
			
			ps_write2: begin 
				if (mem_wr_ack == 1'b1) begin
					mem_wr_addr       <= mem_wr_addr + ADDRESS_INCREMENT;
					pixbuf_state      <= ps_write1;
				end else begin
					mem_wr_req        <= 1'b1;
				end
			end

			//
			// At the end of a frame, force a burst write to memory to clear
			// out the MIG write FIFO. Note that this may corrupt some FIFOs
			// if they do not have protections enabled.
			// 
			ps_flush1: begin //31
				if (mem_wr_ack == 1'b0) begin
					// DDR write request
					pixbuf_state      <= ps_flush2;
					mem_wr_req        <= 1'b1;
				end
			end
			
			ps_flush2: begin //32
				if (mem_wr_ack == 1'b1) begin
					mem_wr_addr       <= mem_wr_addr + ADDRESS_INCREMENT;
					pixbuf_state      <= WaitReset;
					resetCount         <= 4'd0;
					frame_written     <= 1'b1;
				end else begin
					mem_wr_req        <= 1'b1;
				end
			end
		endcase
		
	end
end

// Pixel CLock to MIG Clock CDC
fifo_w64_1024_r128_512 pixelfifo0 (
	.rst                   (fifo_reset), // input rst
	.wr_clk                (clk), // input wr_clk
	.rd_clk                (mem_clk), // input rd_clk
	.din                   (fifo_din), // input [63 : 0] din
	.wr_en                 (fifo_wren), // input wr_en
	.rd_en                 (mem_wdata_rd_en), // input rd_en
	.dout                  (mem_wdf_data), // output [63 : 0] dout
	.full                  (fifo_full), // output full
	.empty                 (fifo_empty), // output empty
	.valid                 (), // output valid
	.wr_data_count         (), // output [8 : 0] wr_data_count
	.rd_data_count         (fifo_rd_data_count), // output [8 : 0] rd_data_count
    .wr_rst_busy           (wr_rst_busy),          // output wire wr_rst_busy
    .rd_rst_busy           (rd_rst_busy)           // output wire rd_rst_busy
);

endmodule

//------------------------------------------------------------------------
// image_if.v
//
// This block operates at the pixel clock and receives pixel data and
// timing from the image sensor.  From an external trigger toggle, an
// image capture is initiated.  The image data is stored to memory using
// an available memory write port.
//
// TRIGGER       - This is a trigger input initiates a capture.
// START_ADDR    - The start (byte) address for storing the next frame.
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
	// Image sensor interface
	output wire          clk, // derived from hispi clock
	input  wire          reset_async,
	output wire          reset_sync,
	input  wire          packing_mode, // TODO: ignored for now...

	input  wire [ 3:0]   slvs_p,
	input  wire [ 3:0]   slvs_n,
	input  wire          slvsc_p,
	input  wire          slvsc_n,
	output wire          cam_reset_b,
	
	input  wire          trigger,
	output reg           frame_done,
	output wire          line_valid,
	output reg           skipped,
	
	output reg  [ 7:0]   sync_error_count,
	
	//MIG Write Interface
	input  wire          mem_clk,
	input  wire          mem_reset,
	
	input  wire [29:0]   start_addr,
	output reg           frame_written,

	output reg           mem_wr_req,
	output reg   [28:0]  mem_wr_addr,
	input  wire          mem_wr_ack,
	
	output wire  [8:0]   fifo_rd_data_count,
	input  wire          mem_wdata_rd_en,
	output wire [255:0]  mem_wdf_data,
	output wire          fifo_full,
	output wire          fifo_empty
	);

localparam BURST_LEN = 6'd1;  //(WORD_SIZE*BURST_MODE/UI_SIZE) = BURST_UI_WORD_COUNT : 16*8/128 = 1
localparam ADDRESS_INCREMENT   = 5'd8; // UI Address is a word address. BL8 Burst Mode = 8.  Memory Width = 32

reg          reg_packing_mode;

wire         fifo_wren;
reg          fifo_reset;
wire [31:0]  fifo_din;

reg  [19:0]  xfer_cnt_pixclk, xfer_cnt_memclk;

wire [39:0]  pix_data;
wire [ 9:0]  sync_word;
wire         sync_sof, sync_sol, sync_eol, sync_eof, sync_error;

reg          enable_pix;
reg          ready_mig, ready_mig_reg, ready_mig_reg1;

reg frame_valid, regm_fv, regm_fv1;

reg  [28:0]  cmd_start_address;

integer state;
localparam s_idle             = 0,
           s_framewait        = 1,
           s_framestore       = 2;

assign fifo_din = {pix_data[9:2],pix_data[19:12],pix_data[29:22],pix_data[39:32]};
assign fifo_wren = line_valid & (state == s_framestore);

always @(posedge clk) begin
	if (reset_sync) begin
		frame_done        <= 1'b0;
		enable_pix        <= 1'b0;
		skipped           <= 1'b0;
		state             <= s_idle;
		reg_packing_mode  <= 1'b0;
		ready_mig_reg     <= 1'b0;
		ready_mig_reg1     <= 1'b0;
		sync_error_count  <= 32'h0;
		frame_valid       <= 1'b0;
	end else begin
		skipped       <= 1'b0;
		frame_done    <= 1'b0;
		ready_mig_reg <= ready_mig;
		ready_mig_reg1 <= ready_mig_reg;
		
		if (sync_error == 1'b1) begin
			sync_error_count <= sync_error_count + 1'b1;
		end
		
		// Handshake with MIG Write Process
		
		case (state)
			s_idle: begin
				// Catch the trigger if it occurs and the MIG side of things
				// is not yet ready, we'll stay in idle to catch any skipped
				// frames as they come by. This is mostly precautionary.
				if (trigger) begin
					enable_pix = 1'b1;
				end
				
				
				xfer_cnt_pixclk <= 17'h00;

				if (enable_pix && ready_mig_reg1) begin
					enable_pix <= 1'b0;
					state <= s_framewait;
				end
				
				// Signal a skipped frame if we see a frame valid come by
				// in the idle state.
				if (sync_sof == 1'b1) begin
					skipped <= 1'b1;
				end
			end
			
			//
			// Once triggered, we wait here for the start of a frame.
			//
			s_framewait: begin
				if (sync_sof == 1'b1) begin
					state <= s_framestore;
					frame_valid <= 1'b1;
				end
			end
			
			
			//
			// Track frames captured
			//
			s_framestore: begin
				if (fifo_wren == 1'b1) begin
					xfer_cnt_pixclk <= xfer_cnt_pixclk + 1'b1;
				end
				
				if (sync_eof == 1'b1) begin
					frame_done <= 1'b1;
					frame_valid <= 1'b0;
					state <= s_idle;
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
always @(posedge mem_clk or posedge mem_reset) begin
	if (mem_reset) begin
		pixbuf_state      <= WaitReset;
		mem_wr_req        <= 1'b0;
		mem_wr_addr       <= 29'h0;
		fifo_reset        <= 1'b1;
		cmd_start_address <= 29'h0;
		frame_written     <= 1'b0;
		ready_mig         <= 1'b0;
		resetCount        <= 4'h0;

		regm_fv1          <= 1'b0;
		regm_fv           <= 1'b0;
	end else begin
		mem_wr_req        <= 1'b0;
		cmd_start_address <= start_addr[29:1];
		fifo_reset        <= 1'b0;
		frame_written     <= 1'b0;
		ready_mig         <= 1'b0;
		regm_fv1 <= regm_fv;
		regm_fv  <= frame_valid;

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
				xfer_cnt_memclk <= 17'h00;
				if (regm_fv1 == 1'b1) begin
					mem_wr_addr  <= cmd_start_address;
					pixbuf_state <= ps_write1;
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
					xfer_cnt_memclk   <= xfer_cnt_memclk + 1'b1;
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

// Pixel Clock to MIG Clock CDC
fifo_w32_2048_r256_256 pixelfifo0 (
	.rst           (fifo_reset), // input rst
	.wr_clk        (clk), // input wr_clk
	.rd_clk        (mem_clk), // input rd_clk
	.din           (fifo_din), // input [63 : 0] din
	.wr_en         (fifo_wren), // input wr_en
	.rd_en         (mem_wdata_rd_en), // input rd_en
	.dout          (mem_wdf_data), // output [255 : 0] dout
	.full          (fifo_full), // output full
	.empty         (fifo_empty), // output empty
	.valid         (), // output valid
	.wr_data_count (), // output [11 : 0] wr_data_count
	.rd_data_count (fifo_rd_data_count), // output [8 : 0] rd_data_count
    .wr_rst_busy   (wr_rst_busy),          // output wire wr_rst_busy
    .rd_rst_busy   (rd_rst_busy)           // output wire rd_rst_busy
);

syzygy_camera_phy camera_phy (
	.clk         (clk),
	.reset_async (reset_async),
	.reset_sync  (reset_sync),

	.slvs_p      (slvs_p),
	.slvs_n      (slvs_n),
	.slvsc_p     (slvsc_p),
	.slvsc_n     (slvsc_n),
	.reset_b     (cam_reset_b),

	.pix_data    (pix_data),
	.line_valid  (line_valid),
	.sync_word   (sync_word),
	.sync_sof    (sync_sof),
	.sync_sol    (sync_sol),
	.sync_eol    (sync_eol),
	.sync_eof    (sync_eof),
	.sync_error  (sync_error)
);

endmodule

//------------------------------------------------------------------------
// image_if.v
//
// This block operates at the pixel clock and receives pixel data and
// timing from the image sensor.  From an external trigger toggle, an
// image capture is initiated.  The image data is stored to memory using
// an available memory write port.
//
// trigger       - This is a trigger input initiates a capture.
// start_addr    - The start (byte) address for storing the next frame.
// frame_done    - Asserted at completion of a stored frame.
// frame_written - Asserted after a frame has been written to memory
//
// Copyright (c) 2004-2022 Opal Kelly Incorporated
//------------------------------------------------------------------------
`timescale 1ns / 1ps
module image_if(
    // Image sensor interface
    output wire          clk, // derived from hispi clock
    input  wire          reset_async,
    input  wire          clk_ti,
    output wire          reset_sync,

    input  wire [ 3:0]   slvs_p,
    input  wire [ 3:0]   slvs_n,
    input  wire          slvsc_p,
    input  wire          slvsc_n,
    output wire          cam_reset_b,
    
    input  wire          trigger,
    output reg           frame_done,
    output wire          line_valid,
    output reg           skipped,
    
    output reg  [7:0]    sync_error_count,
    
    //MIG Write Interface
    input  wire          mem_clk,
    input  wire          mem_reset,
    
    input  wire [29:0]   start_addr,
    output reg           frame_written,

    output reg           mem_wr_req,
    output reg  [28:0]   mem_wr_addr,
    input  wire          mem_wr_ack,
    
    output wire [12:0]    fifo_rd_data_count,
    input  wire          mem_wdata_rd_en,
    output wire [127:0]  mem_wdf_data,
    output wire          fifo_full,
    output wire          fifo_empty,
    output wire [31:0]  hist_out,
    output wire         hist_ready,
    input wire          hist_rden,
    output wire          hist_empty,
    input  wire          idelay_rdy,
    input wire [15:0]         height,
    input wire [15:0]         width,
       
    input wire [31:0]    rgain, 
    input wire [31:0]    ggain, 
    input wire [31:0]    bgain,
    input wire [31:0]    blc,
    input wire [31:0]    thresh
    
    );

localparam BURST_LEN           = 6'd1;  //(WORD_SIZE*BURST_MODE/UI_SIZE) = BURST_UI_WORD_COUNT : 16*8/128 = 1
localparam ADDRESS_INCREMENT   = 5'd8; // UI Address is a word address. BL8 Burst Mode = 8.  Memory Width = 32


wire         fifo_wren;
reg          fifo_reset;
wire [127:0]  fifo_din;

reg  [19:0]  xfer_cnt_pixclk;
reg  [19:0]  xfer_cnt_memclk;

wire [39:0]  pix_data;
wire [ 9:0]  sync_word;
wire         sync_sof;
wire         sync_sol;
wire         sync_eol;
wire         sync_eof;
wire         sync_error;

reg          enable_pix;
reg          ready_mig;
reg          ready_mig_reg;
reg          ready_mig_reg1;

reg          frame_valid;
reg          regm_fv;
reg          regm_fv1;

reg          sync_eof_happened;

reg  [28:0]  cmd_start_address;
reg [15:0] line_count;

wire axis_video_sof,axis_video_eol;

reg  [3:0]   resetCount;

wire [7:0]  pix_data_green;
wire [7:0]  pix_data_red;
wire [7:0]  pix_data_blue;
wire [7:0]  pix_data_green2;
wire [31:0] vid_data;

wire [31 : 0]   axis_video_in_to_hls_tdata;
wire            axis_video_in_to_hls_tvalid;
wire            axis_video_in_to_hls_tready;
wire            axis_video_in_to_hls_tuser;
wire            axis_video_in_to_hls_tlast;

wire [95 : 0]   axis_hls_to_fifo_tdata;
wire            axis_hls_to_fifo_tvalid;
wire            axis_hls_to_fifo_tready;
wire            axis_hls_to_fifo_tuser;
wire            axis_hls_to_fifo_tlast;

wire hist_wr_rst_busy;
wire hist_rd_rst_busy;
wire hist_write;
wire hist_full;
wire hist_prog_full;
wire [31:0] hist_din;

integer      state;
localparam   s_idle             = 0,
             s_framewait        = 1,
             s_framestore       = 2;

assign pix_data_green = pix_data[39:32];
assign pix_data_red = pix_data[29:22];
assign pix_data_blue = pix_data[19:12];
assign pix_data_green2 = pix_data[9:2];


assign axis_video_sof = axis_hls_to_fifo_tuser;
assign axis_video_eol = axis_hls_to_fifo_tlast;

assign fifo_din  = {axis_hls_to_fifo_tdata[23:0],8'hff,axis_hls_to_fifo_tdata[ 47:24],8'hff,axis_hls_to_fifo_tdata[71:48],8'hff,axis_hls_to_fifo_tdata[ 95:72],8'hff};
//assign fifo_din  = {axis_hls_to_fifo_tdata[7:0],axis_hls_to_fifo_tdata[31:24],axis_hls_to_fifo_tdata[55:48],axis_hls_to_fifo_tdata[79   :72]};
assign fifo_wren = axis_hls_to_fifo_tready && axis_hls_to_fifo_tvalid;
assign axis_hls_to_fifo_tready = !fifo_full && (state == s_framestore);
    

always @(posedge clk) begin
    if (reset_sync) begin
        frame_done        <= 1'b0;
        enable_pix        <= 1'b0;
        skipped           <= 1'b0;
        line_count        <= 16'd0;
        state             <= s_idle;
        ready_mig_reg     <= 1'b0;
        ready_mig_reg1    <= 1'b0;
        sync_error_count  <= 32'h0;
        frame_valid       <= 1'b0;
    end else begin    
        skipped           <= 1'b0;
        frame_done        <= 1'b0;
        ready_mig_reg     <= ready_mig;
        ready_mig_reg1    <= ready_mig_reg;
        
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
                    enable_pix          = 1'b1;
                end

                xfer_cnt_pixclk        <= 17'h00;

                if (enable_pix && ready_mig_reg1) begin
                    enable_pix         <= 1'b0;
                    state              <= s_framewait;
                end
                
                // Signal a skipped frame if we see a frame valid come by
                // in the idle state.
                if (sync_sof == 1'b1) begin
                    skipped            <= 1'b1;
                end
            end
            
            // Once triggered, we wait here for the start of a frame.
            s_framewait: begin
                if (axis_video_sof && axis_hls_to_fifo_tvalid) begin
                    state              <= s_framestore;
                    frame_valid        <= 1'b1;
                    line_count <= 16'd0;
                end
            end
            
            // Track frames captured
            s_framestore: begin
                if (fifo_wren == 1'b1) begin
                    xfer_cnt_pixclk    <= xfer_cnt_pixclk + 1'b1;
                end
                
                if (axis_video_eol && axis_hls_to_fifo_tvalid && axis_hls_to_fifo_tready ) begin
                    if (line_count >= height - 1) begin                
                        frame_done         <= 1'b1;
                        frame_valid        <= 1'b0;
                        state              <= s_idle;
                    end
                    else begin
                        line_count <= line_count + 16'd1;
                    end
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
           ps_flush1 = 31,
           ps_flush2 = 32;
wire    wr_rst_busy;
wire    rd_rst_busy;
always @(posedge mem_clk or posedge mem_reset) begin
    if (mem_reset) begin
        pixbuf_state      <= WaitReset;
        mem_wr_req        <= 1'b0;
        mem_wr_addr       <= 29'h0;
        fifo_reset        <= 1'b1;
        cmd_start_address <= 29'h0;
        frame_written     <= 1'b0;
        ready_mig         <= 1'b0;

        regm_fv1          <= 1'b0;
        regm_fv           <= 1'b0;
        resetCount        <= 1'b0;
    end else begin
        mem_wr_req        <= 1'b0;
        cmd_start_address <= start_addr[28:0];
        fifo_reset        <= 1'b0;
        frame_written     <= 1'b0;
        ready_mig         <= 1'b0;
        regm_fv1          <= regm_fv;
        regm_fv           <= frame_valid;

        case (pixbuf_state)
            WaitReset: begin
                if (resetCount > 4'd11) begin
                    if(!wr_rst_busy && !rd_rst_busy) begin
                        pixbuf_state       <= ps_idle;
                    end
                end else begin
                    fifo_reset         <= 1'b1;
                    resetCount         <= resetCount + 1'b1;
                end
            end
            ps_idle: begin
                ready_mig              <= 1'b1;
                xfer_cnt_memclk        <= 17'h00;
                if (regm_fv1 == 1'b1) begin
                    mem_wr_addr        <= cmd_start_address;
                    pixbuf_state       <= ps_write1;
                end
            end
            
            // Signal the memory controller to write bursts of image data to the memory
            // when enough data is built up in the FIFO.
            ps_write1: begin
                if (regm_fv1 == 1'b0 && fifo_empty) begin
                    pixbuf_state       <= WaitReset;
                    fifo_reset         <= 1'b1;
                    resetCount         <= 4'd0;
                    frame_written      <= 1'b1;
                end
                
                if ((fifo_rd_data_count >= BURST_LEN) && (mem_wr_ack == 1'b0) ) begin
                    // DDR write request
                    pixbuf_state       <= ps_write2;
                    mem_wr_req         <= 1'b1;
                end
            end
            
            ps_write2: begin 
                if (mem_wr_ack == 1'b1) begin
                    mem_wr_addr        <= mem_wr_addr + ADDRESS_INCREMENT;
                    pixbuf_state       <= ps_write1;
                    xfer_cnt_memclk    <= xfer_cnt_memclk + 1'b1;
                end else begin
                    mem_wr_req         <= 1'b1;
                end
            end

            // At the end of a frame, force a burst write to memory to clear
            // out the MIG write FIFO. Note that this may corrupt some FIFOs
            // if they do not have protections enabled.
            ps_flush1: begin //31
                if (mem_wr_ack == 1'b0) begin
                    // DDR write request
                    pixbuf_state       <= ps_flush2;
                    mem_wr_req         <= 1'b1;
                end
            end
            
            ps_flush2: begin //32
                if (mem_wr_ack == 1'b1) begin
                    mem_wr_addr        <= mem_wr_addr + ADDRESS_INCREMENT;
                    pixbuf_state       <= ps_idle;
                    fifo_reset         <= 1'b1;
                    frame_written      <= 1'b1;
                end else begin
                    mem_wr_req         <= 1'b1;
                end
            end
        endcase
        
    end
end

// Pixel CLock to MIG Clock CDC
fifo_w128_8192_r128_8192 pix_clk_to_mem_clk_fifo (
  .rst                  (fifo_reset),           // input wire rst
  .wr_clk               (clk),                  // input wire wr_clk
  .rd_clk               (mem_clk),              // input wire rd_clk
  .din                  (fifo_din),             // input wire [31 : 0] din
  .wr_en                (fifo_wren),            // input wire wr_en
  .rd_en                (mem_wdata_rd_en),      // input wire rd_en
  .dout                 (mem_wdf_data),         // output wire [127 : 0] dout
  .full                 (fifo_full),            // output wire full
  .empty                (fifo_empty),           // output wire empty
  .valid                (),                     // output wire valid
  .wr_data_count        (),                     // output wire [12 : 0] wr_data_count
  .rd_data_count        (fifo_rd_data_count),   // output wire [12 : 0] rd_data_count
  .wr_rst_busy          (wr_rst_busy),          // output wire wr_rst_busy
  .rd_rst_busy          (rd_rst_busy)           // output wire rd_rst_busy
);

//axiconv_accel_0 axiconv_accel_0_i (
//  .src_TDATA(axis_video_in_to_hls_tdata),    // input wire [31 : 0] src_TDATA
//  .src_TLAST(axis_video_in_to_hls_tlast),    // input wire [0 : 0] src_TLAST
//  .src_TREADY(axis_video_in_to_hls_tready),  // output wire src_TREADY
//  .src_TUSER(axis_video_in_to_hls_tuser),    // input wire [0 : 0] src_TUSER
//  .src_TVALID(axis_video_in_to_hls_tvalid),  // input wire src_TVALID
//  .src_TKEEP(4'b1111),    // input wire [3 : 0] src_TKEEP
//  .src_TSTRB(4'b1111),    // input wire [3 : 0] src_TSTRB
  
//  .dst_TDATA(axis_hls_to_fifo_tdata),    // output wire [31 : 0] dst_TDATA
//  .dst_TREADY(axis_hls_to_fifo_tready),  // input wire dst_TREADY
//  .dst_TVALID(axis_hls_to_fifo_tvalid),  // output wire dst_TVALID
//  .dst_TUSER(axis_hls_to_fifo_tuser),  // output wire dst_TUSER
//  .dst_TLAST(axis_hls_to_fifo_tlast),  // output wire dst_TLAST
  
//  .rows(32'd432),              // input wire [31 : 0] rows
//  .cols(32'd768),              // input wire [31 : 0] cols
//  .ap_clk(clk),          // input wire ap_clk
//  .ap_rst_n(~reset_sync),      // input wire ap_rst_n
//  .ap_start(1'b1)      // input wire ap_start
//);


ISPPipeline_accel_0 ISPPipeline_accel_0_i (
  .ap_clk(clk),
  .ap_rst_n(~reset_sync),
  .ap_start(1'b1),
  .rgain(rgain),
  .ggain(ggain),
  .bgain(bgain),
  .height(height),
  .width(width),
  .thresh(thresh),
  .blackLevelCorrection(blc),
  .s_axis_video_TDATA(axis_video_in_to_hls_tdata),
  .s_axis_video_TKEEP(4'b1111),
  .s_axis_video_TLAST(axis_video_in_to_hls_tlast),
  .s_axis_video_TREADY(axis_video_in_to_hls_tready),
  .s_axis_video_TSTRB(4'b1111),
  .s_axis_video_TUSER(axis_video_in_to_hls_tuser),
  .s_axis_video_TVALID(axis_video_in_to_hls_tvalid),
  .m_axis_video_TDATA(axis_hls_to_fifo_tdata),
  .m_axis_video_TLAST(axis_hls_to_fifo_tlast),
  .m_axis_video_TREADY(axis_hls_to_fifo_tready),
  .m_axis_video_TUSER(axis_hls_to_fifo_tuser),
  .m_axis_video_TVALID(axis_hls_to_fifo_tvalid),
  .hist_din(hist_din),
  .hist_full_n(~hist_full|| ~hist_wr_rst_busy),
  .hist_write(hist_write)
);
hist_fifo hist_fifo_i(
    .wr_clk(clk),
    .rd_clk(clk_ti),
    .srst(reset_sync),
    .din(hist_din),
    .wr_en(hist_write),
    .rd_en(hist_rden),
    .dout(hist_out),
    .full(hist_full),
    .empty(hist_empty),
    .wr_rst_busy(hist_wr_rst_busy),
    .rd_rst_busy(hist_rd_rst_busy),
    .prog_full(hist_prog_full)
);

assign hist_ready = hist_prog_full && !hist_wr_rst_busy && !hist_rd_rst_busy;

v_vid_in_axi4s_0 v_vid_in_axi4s_0_i (
  .vid_io_in_ce(1'b1),                  // input wire vid_io_in_ce
  .vid_active_video(line_valid),        // input wire vid_active_video
  .vid_vblank(1'b0),                    // input wire vid_vblank
  .vid_hblank(1'b0),                    // input wire vid_hblank
  .vid_vsync(sync_sof),                 // input wire vid_vsync
  .vid_hsync(sync_sol),                 // input wire vid_hsync
  .vid_field_id(1'b0),                  // input wire vid_field_id
  .vid_data({pix_data[39:32],pix_data[29:22],pix_data[19:12],pix_data[9:2]}),  // input wire [31 : 0] vid_data
  .aclk(clk),                           // input wire aclk
  .aclken(1'b1),                        // input wire aclken
  .aresetn(~reset_sync),               // input wire aresetn
  .m_axis_video_tdata(axis_video_in_to_hls_tdata),    // output wire [31 : 0] m_axis_video_tdata
  .m_axis_video_tvalid(axis_video_in_to_hls_tvalid),  // output wire m_axis_video_tvalid
  .m_axis_video_tready(axis_video_in_to_hls_tready),  // input wire m_axis_video_tready
  .m_axis_video_tuser(axis_video_in_to_hls_tuser),    // output wire m_axis_video_tuser
  .m_axis_video_tlast(axis_video_in_to_hls_tlast),    // output wire m_axis_video_tlast
  .fid(),                                     // output wire fid
  .overflow(),                        // output wire overflow
  .underflow(),                      // output wire underflow
  .axis_enable(1'b1)                   // input wire axis_enable
);

syzygy_camera_phy camera_phy (
    .clk                (clk),                  // output
    .reset_async        (reset_async),          // input
    .reset_sync_out     (reset_sync),           // output

    .slvs_p             (slvs_p),               // input [3:0]
    .slvs_n             (slvs_n),               // input [3:0]
    .slvsc_p            (slvsc_p),              // input
    .slvsc_n            (slvsc_n),              // input
    .reset_b            (cam_reset_b),          // output

    .pix_data           (pix_data),             // output [39:0]
    .line_valid         (line_valid),           // output
    .sync_word          (sync_word),            // output [9:0]
    .sync_sof           (sync_sof),             // output
    .sync_sol           (sync_sol),             // output
    .sync_eol           (sync_eol),             // output
    .sync_eof           (sync_eof),             // output
    .sync_error         (sync_error),           // output
    .idelay_rdy         (idelay_rdy)            // input
);

endmodule
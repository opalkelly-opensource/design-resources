//------------------------------------------------------------------------
// image_if_wrapper.v
//
// This is a wrapper for the image interfaces. First a start trigger and 
// address comes in from the system to the first interface. Once the first 
// interface has written the image to DDR memory, a trigger and address is 
// then sent to the next interface to start the capture and store process 
// into DDR memory. A start trigger and address is finally sent to the last 
// interface and after capture and store a frame_done signal is output from 
// this module to notify the system this process has completed.
//
//------------------------------------------------------------------------
// Copyright (c) 2005-2022 Opal Kelly Incorporated
//------------------------------------------------------------------------
`timescale 1ns / 1ps
`default_nettype none
module image_if_wrapper(
    // Image sensor interface
    output wire          clk_first,   // derived from hispi clock
    output wire          clk_last,    // derived from hispi clock
    input  wire          reset_async,
    output wire          reset_pixclk_first,
    output wire          reset_pixclk_last,

    input  wire [ 3:0]   slvs_p,
    input  wire [ 3:0]   slvs_n,
    input  wire          slvsc_p,
    input  wire          slvsc_n,

    input  wire [ 3:0]   slvs_p_2,
    input  wire [ 3:0]   slvs_n_2,
    input  wire          slvsc_p_2,
    input  wire          slvsc_n_2,
    
    input  wire [ 3:0]   slvs_p_3,
    input  wire [ 3:0]   slvs_n_3,
    input  wire          slvsc_p_3,
    input  wire          slvsc_n_3,
   
    input  wire          trigger,
    output wire          frame_done,
    
    
    //MIG Write Interface
    input  wire          mem_clk,
    input  wire          mem_reset,
    
    input  wire [29:0]   start_addr,
    output wire          frame_written,

    output wire          mem_wr_req,
    output reg  [28:0]   mem_wr_addr,
    input  wire          mem_wr_ack,
    
    output wire [8:0]    fifo_rd_data_count,
    input  wire          mem_wdata_rd_en,
    output reg  [127:0]  mem_wdf_data,
    
    
    output wire          fifo_full,
    output wire          fifo_empty,
    input  wire          idelay_rdy
    );
wire         clk_middle;
wire         reset_pixclk_middle;
    
wire         camera_fifo_full;
wire         camera_fifo_full_2;
wire         camera_fifo_full_3;
wire         camera_fifo_empty;
wire         camera_fifo_empty_2;
wire         camera_fifo_empty_3;
wire         frame_written_camera_1;
wire         frame_written_camera_2;
wire         frame_written_camera_3;

wire         memarb_wr_req;
wire         memarb_wr_req_2;
wire         memarb_wr_req_3;
wire [8:0]   wr_fifo_count;
wire [8:0]   wr_fifo_count_2;
wire [8:0]   wr_fifo_count_3;

wire [127:0] memif_app_wdf_data;
wire [127:0] memif_app_wdf_data_2;
wire [127:0] memif_app_wdf_data_3;

wire [28:0]  memarb_wr_addr;
wire [28:0]  memarb_wr_addr_2;
wire [28:0]  memarb_wr_addr_3;

wire [29:0]  saved_addr;
wire [29:0]  saved_addr_2;

wire trigger_clk_2;
wire trigger_clk_3;
reg [1:0] choose_output = 2'b00;

assign fifo_full          = camera_fifo_full | camera_fifo_full_2 | camera_fifo_full_3;
assign fifo_empty         = camera_fifo_empty | camera_fifo_empty_2 | camera_fifo_empty_3;

assign mem_wr_req         = memarb_wr_req | memarb_wr_req_2 | memarb_wr_req_3;
assign fifo_rd_data_count = wr_fifo_count + wr_fifo_count_2 + wr_fifo_count_3;

assign frame_written      = frame_written_camera_3;

always @(posedge mem_clk) begin
    if (frame_written_camera_1) begin
        choose_output <= 2'b01;
    end else if (frame_written_camera_2) begin
        choose_output <= 2'b10;
    end else if (frame_written_camera_3) begin
        choose_output <= 2'b00;
    end
end

always @(*) begin
    if (choose_output == 2'b00) begin
        mem_wdf_data = memif_app_wdf_data;
        mem_wr_addr  = memarb_wr_addr;
    end else if (choose_output == 2'b01) begin
        mem_wdf_data = memif_app_wdf_data_2;
        mem_wr_addr  = memarb_wr_addr_2;
    end else if (choose_output == 2'b10) begin
        mem_wdf_data = memif_app_wdf_data_3;
        mem_wr_addr  = memarb_wr_addr_3;
    end
end

image_if imgif_1(
    .clk                        (clk_first),                    // output
    .reset_async                (reset_async),                  // input
    .reset_sync                 (reset_pixclk_first),           // output
    
    .slvs_p                     (slvs_p),                       // input  [3:0]
    .slvs_n                     (slvs_n),                       // input  [3:0]
    .slvsc_p                    (slvsc_p),                      // input
    .slvsc_n                    (slvsc_n),                      // input
    
    .trigger                    (trigger),                      // input
    .frame_done                 (),                             // output
    .line_valid                 (),                             // output
    .skipped                    (),                             // output
    
    .sync_error_count           (),                             // output [7:0]
    
    .fifo_full                  (camera_fifo_full),             // output
    .fifo_empty                 (camera_fifo_empty),            // output
    .idelay_rdy                 (idelay_rdy),                   // input
    
    //MIG Write Interface
    .mem_clk                    (mem_clk),                      // input
    .mem_reset                  (mem_reset),                    // input
    
    .start_addr                 (start_addr),                   // input  [29:0]
    .saved_addr                 (saved_addr),                   // output [29:0]
    .frame_written              (frame_written_camera_1),       // output
    
    .mem_wr_req                 (memarb_wr_req),                // output
    .mem_wr_addr                (memarb_wr_addr),               // output [28:0]
    .mem_wr_ack                 (mem_wr_ack),                   // input
    
    .fifo_rd_data_count         (wr_fifo_count),                // output [8:0]
    .mem_wdata_rd_en            (mem_wdata_rd_en),              // input
    .mem_wdf_data               (memif_app_wdf_data)            // output [127:0]
    
    

);

sync_trig sync_imgif_trig_1_2(
    .clk_i                      (mem_clk),                      // input
    .clk_o                      (clk_middle),                   // input
    .rst_i                      (mem_reset),                    // input
    .rst_o                      (reset_pixclk_middle),          // input
    .trig_i                     (frame_written_camera_1),       // input
    .trig_o                     (trigger_clk_2)                 // output
);

image_if imgif_2(
    .clk                        (clk_middle),                   // output
    .reset_async                (reset_async),                  // input
    .reset_sync                 (reset_pixclk_middle),          // output
    
    .slvs_p                     (slvs_p_2),                     // input  [3:0]
    .slvs_n                     (slvs_n_2),                     // input  [3:0]
    .slvsc_p                    (slvsc_p_2),                    // input
    .slvsc_n                    (slvsc_n_2),                    // input
    
    .trigger                    (trigger_clk_2),                // input
    .frame_done                 (),                             // output
    .line_valid                 (),                             // output
    .skipped                    (),                             // output
    
    .fifo_full                  (camera_fifo_full_2),           // output
    .fifo_empty                 (camera_fifo_empty_2),          // output
    .idelay_rdy                 (idelay_rdy),                   // input
    
    //MIG Write Interface
    .sync_error_count           (),                             // output [7:0]
    
    .mem_clk                    (mem_clk),                      // input
    .mem_reset                  (mem_reset),                    // input
    
    .start_addr                 (saved_addr),                   // input  [29:0]
    .saved_addr                 (saved_addr_2),                 // output [29:0]
    .frame_written              (frame_written_camera_2),       // output
    
    .mem_wr_req                 (memarb_wr_req_2),              // output
    .mem_wr_addr                (memarb_wr_addr_2),             // output [28:0]
    .mem_wr_ack                 (mem_wr_ack),                   // input
    
    .fifo_rd_data_count         (wr_fifo_count_2),              // output [8:0]
    .mem_wdata_rd_en            (mem_wdata_rd_en),              // input
    .mem_wdf_data               (memif_app_wdf_data_2)          // output [127:0]
    
    
);

sync_trig sync_imgif_trig_2_3(
    .clk_i                      (mem_clk),                      // input
    .clk_o                      (clk_last),                     // input
    .rst_i                      (mem_reset),                    // input
    .rst_o                      (reset_pixclk_last),            // input
    .trig_i                     (frame_written_camera_2),       // input
    .trig_o                     (trigger_clk_3)                 // output
);

image_if imgif_3(
    .clk                        (clk_last),                     // output
    .reset_async                (reset_async),                  // input
    .reset_sync                 (reset_pixclk_last),            // output
    
    .slvs_p                     (slvs_p_3),                     // input  [3:0]
    .slvs_n                     (slvs_n_3),                     // input  [3:0]
    .slvsc_p                    (slvsc_p_3),                    // input
    .slvsc_n                    (slvsc_n_3),                    // input
    
    .trigger                    (trigger_clk_3),                // input
    .frame_done                 (frame_done),                   // output
    .line_valid                 (),                             // output
    .skipped                    (),                             // output
    
    .fifo_full                  (camera_fifo_full_3),           // output
    .fifo_empty                 (camera_fifo_empty_3),          // output
    .idelay_rdy                 (idelay_rdy),                   // input
    
    //MIG Write Interface
    .sync_error_count           (),                             // output [7:0]
    
    .mem_clk                    (mem_clk),                      // input
    .mem_reset                  (mem_reset),                    // input
    
    .start_addr                 (saved_addr_2),                 // input  [29:0]
    .frame_written              (frame_written_camera_3),       // output
    
    .mem_wr_req                 (memarb_wr_req_3),              // output
    .mem_wr_addr                (memarb_wr_addr_3),             // output [28:0]
    .mem_wr_ack                 (mem_wr_ack),                   // input
    
    .fifo_rd_data_count         (wr_fifo_count_3),              // output [8:0]
    .mem_wdata_rd_en            (mem_wdata_rd_en),              // input
    .mem_wdf_data               (memif_app_wdf_data_3)          // output [127:0]
    
    
);

endmodule
`default_nettype wire

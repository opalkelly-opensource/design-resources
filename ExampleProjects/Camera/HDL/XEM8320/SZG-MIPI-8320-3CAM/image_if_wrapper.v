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
    input  wire          clk, 
    input  wire          reset,
    input  wire          reset_mipi,
    input  wire          ctrl_core_en,
    input  wire          dphy_clk_200M,

    // Camera 1
    input  wire  [0:0]   mipi_phy_if_clk_p_1,
    input  wire  [0:0]   mipi_phy_if_clk_n_1,
    input  wire  [1:0]   mipi_phy_if_data_p_1,
    input  wire  [1:0]   mipi_phy_if_data_n_1,
    
    // Camera 2
    input  wire  [0:0]   mipi_phy_if_clk_p_2,
    input  wire  [0:0]   mipi_phy_if_clk_n_2,
    input  wire  [1:0]   mipi_phy_if_data_p_2,
    input  wire  [1:0]   mipi_phy_if_data_n_2,
    
    // Camera 3
    input  wire  [0:0]   mipi_phy_if_clk_p_3,
    input  wire  [0:0]   mipi_phy_if_clk_n_3,
    input  wire  [1:0]   mipi_phy_if_data_p_3,
    input  wire  [1:0]   mipi_phy_if_data_n_3,
   
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
    output wire          fifo_empty
    );
    
localparam MASTER_CAMERA_1_INTERFACE = 0,
           SLAVE_CAMERA_2_INTERFACE  = 1,
           SLAVE_CAMERA_3_INTERFACE  = 2;
    
wire         camera_fifo_full_1;
wire         camera_fifo_full_2;
wire         camera_fifo_full_3;
wire         camera_fifo_empty_1;
wire         camera_fifo_empty_2;
wire         camera_fifo_empty_3;
wire         frame_written_camera_1;
wire         frame_written_camera_2;

wire         memarb_wr_req_1;
wire         memarb_wr_req_2;
wire         memarb_wr_req_3;

wire [8:0]   wr_fifo_count_1;
wire [8:0]   wr_fifo_count_2;
wire [8:0]   wr_fifo_count_3;

wire [127:0] memif_app_wdf_data_1;
wire [127:0] memif_app_wdf_data_2;
wire [127:0] memif_app_wdf_data_3;

wire [28:0]  memarb_wr_addr_1;
wire [28:0]  memarb_wr_addr_2;
wire [28:0]  memarb_wr_addr_3;

wire [29:0]  saved_addr_camera_1;
wire [29:0]  saved_addr_camera_2;

wire trigger_camera_2;
wire trigger_camera_3;

wire pll_lock_out;
wire clkoutphy_out;

reg  [1:0] choose_output = 2'b00;

assign fifo_full          = camera_fifo_full_1 | camera_fifo_full_2 | camera_fifo_full_3;
assign fifo_empty         = camera_fifo_empty_1 | camera_fifo_empty_2 | camera_fifo_empty_3;

assign mem_wr_req         = memarb_wr_req_1 | memarb_wr_req_2 | memarb_wr_req_3;
assign fifo_rd_data_count = wr_fifo_count_1 + wr_fifo_count_2 + wr_fifo_count_3;

always @(posedge mem_clk) begin
    if (frame_written_camera_1) begin
        choose_output <= 2'b01;
    end else if (frame_written_camera_2) begin
        choose_output <= 2'b10;
    end else if (frame_written) begin
        choose_output <= 2'b00;
    end
end

always @(*) begin
    if (choose_output == 2'b00) begin
        mem_wdf_data = memif_app_wdf_data_1;
        mem_wr_addr  = memarb_wr_addr_1;
    end else if (choose_output == 2'b01) begin
        mem_wdf_data = memif_app_wdf_data_2;
        mem_wr_addr  = memarb_wr_addr_2;
    end else begin
        mem_wdf_data = memif_app_wdf_data_3;
        mem_wr_addr  = memarb_wr_addr_3;
    end
end

image_if #(
.CAMERA_INTERFACE(MASTER_CAMERA_1_INTERFACE)
) imgif_cam1_master_i(
    .clk                        (clk),                          // input
    .reset                      (reset),                        // input
    .reset_mipi                 (reset_mipi),                   // input
    .ctrl_core_en               (ctrl_core_en),                 // input
    .dphy_clk_200M              (dphy_clk_200M),                // input
    
    // MIPI interface
    .mipi_phy_if_clk_p          (mipi_phy_if_clk_p_1),          // input
    .mipi_phy_if_clk_n          (mipi_phy_if_clk_n_1),          // input
    .mipi_phy_if_data_p         (mipi_phy_if_data_p_1),         // input  [1:0]
    .mipi_phy_if_data_n         (mipi_phy_if_data_n_1),         // input  [1:0]
    
    .trigger                    (trigger),                      // input
    .frame_done                 (),                             // output
    .line_valid                 (),                             // output
    .skipped                    (),                             // output
    
    .sync_error_count           (),                             // output [7:0]
    
    .fifo_full                  (camera_fifo_full_1),           // output
    .fifo_empty                 (camera_fifo_empty_1),          // output
    
    //MIG Write Interface
    .mem_clk                    (mem_clk),                      // input
    .mem_reset                  (mem_reset),                    // input
    
    .start_addr                 (start_addr),                   // input  [29:0]
    .saved_addr                 (saved_addr_camera_1),          // output  [29:0]
    .frame_written              (frame_written_camera_1),       // output
    
    .mem_wr_req                 (memarb_wr_req_1),              // output
    .mem_wr_addr                (memarb_wr_addr_1),             // output [28:0]
    .mem_wr_ack                 (mem_wr_ack),                   // input
    
    .fifo_rd_data_count         (wr_fifo_count_1),              // output [8:0]
    .mem_wdata_rd_en            (mem_wdata_rd_en),              // input
    .mem_wdf_data               (memif_app_wdf_data_1),         // output [127:0]
    
    .pll_lock_out               (pll_lock_out),                 // output
    .clkoutphy_out              (clkoutphy_out)                 // output 

);


sync_trig sync_imgif_trig_1(
    .clk_i                      (mem_clk),                      // input
    .clk_o                      (clk),                          // input
    .rst_i                      (mem_reset),                    // input
    .rst_o                      (reset),                        // input
    .trig_i                     (frame_written_camera_1),       // input
    .trig_o                     (trigger_camera_2)              // output
);

image_if #(
.CAMERA_INTERFACE(SLAVE_CAMERA_2_INTERFACE) // 1 = MASTER, 0 = SLAVE
) imgif_cam2_slave_i(
    .clk                        (clk),                          // input
    .reset                      (reset),                        // input
    .reset_mipi                 (reset_mipi),                   // input
    .ctrl_core_en               (ctrl_core_en),                 // input
    .dphy_clk_200M              (dphy_clk_200M),                // input
    
    // MIPI interface
    .mipi_phy_if_clk_p          (mipi_phy_if_clk_p_2),          // input
    .mipi_phy_if_clk_n          (mipi_phy_if_clk_n_2),          // input
    .mipi_phy_if_data_p         (mipi_phy_if_data_p_2),         // input  [1:0]
    .mipi_phy_if_data_n         (mipi_phy_if_data_n_2),         // input  [1:0]
    
    .trigger                    (trigger_camera_2),             // input
    .frame_done                 (),                             // output
    .line_valid                 (),                             // output
    .skipped                    (),                             // output
    
    .fifo_full                  (camera_fifo_full_2),           // output
    .fifo_empty                 (camera_fifo_empty_2),          // output
    
    //MIG Write Interface
    .sync_error_count           (),                             // output [7:0]
    
    .mem_clk                    (mem_clk),                      // input
    .mem_reset                  (mem_reset),                    // input
    
    .start_addr                 (saved_addr_camera_1),          // input  [29:0]
    .saved_addr                 (saved_addr_camera_2),          // output  [29:0]
    .frame_written              (frame_written_camera_2),       // output
    
    .mem_wr_req                 (memarb_wr_req_2),              // output
    .mem_wr_addr                (memarb_wr_addr_2),             // output [28:0]
    .mem_wr_ack                 (mem_wr_ack),                   // input
    
    .fifo_rd_data_count         (wr_fifo_count_2),              // output [8:0]
    .mem_wdata_rd_en            (mem_wdata_rd_en),              // input
    .mem_wdf_data               (memif_app_wdf_data_2),         // output [127:0]
    .clkoutphy_in               (clkoutphy_out),                // input wire clkoutphy_in
    .pll_lock_in                (pll_lock_out)                  // input wire pll_lock_in
    
    
);

sync_trig sync_imgif_trig_2(
    .clk_i                      (mem_clk),                      // input
    .clk_o                      (clk),                          // input
    .rst_i                      (mem_reset),                    // input
    .rst_o                      (reset),                        // input
    .trig_i                     (frame_written_camera_2),       // input
    .trig_o                     (trigger_camera_3)              // output
);

image_if #(
.CAMERA_INTERFACE(SLAVE_CAMERA_3_INTERFACE)
) imgif_cam3_slave_i(
    .clk                        (clk),                          // input
    .reset                      (reset),                        // input
    .reset_mipi                 (reset_mipi),                   // input
    .ctrl_core_en               (ctrl_core_en),                 // input
    .dphy_clk_200M              (dphy_clk_200M),                // input
    
    // MIPI interface
    .mipi_phy_if_clk_p          (mipi_phy_if_clk_p_3),          // input
    .mipi_phy_if_clk_n          (mipi_phy_if_clk_n_3),          // input
    .mipi_phy_if_data_p         (mipi_phy_if_data_p_3),         // input  [1:0]
    .mipi_phy_if_data_n         (mipi_phy_if_data_n_3),         // input  [1:0]
    
    .trigger                    (trigger_camera_3),             // input
    .frame_done                 (frame_done),                   // output
    .line_valid                 (),                             // output
    .skipped                    (),                             // output
    
    .fifo_full                  (camera_fifo_full_3),           // output
    .fifo_empty                 (camera_fifo_empty_3),          // output
    
    //MIG Write Interface
    .sync_error_count           (),                             // output [7:0]
    
    .mem_clk                    (mem_clk),                      // input
    .mem_reset                  (mem_reset),                    // input
    
    .start_addr                 (saved_addr_camera_2),          // input  [29:0]
    .frame_written              (frame_written),                // output
    
    .mem_wr_req                 (memarb_wr_req_3),              // output
    .mem_wr_addr                (memarb_wr_addr_3),             // output [28:0]
    .mem_wr_ack                 (mem_wr_ack),                   // input
    
    .fifo_rd_data_count         (wr_fifo_count_3),              // output [8:0]
    .mem_wdata_rd_en            (mem_wdata_rd_en),              // input
    .mem_wdf_data               (memif_app_wdf_data_3),         // output [127:0]
    .clkoutphy_in               (clkoutphy_out),                // input wire clkoutphy_in
    .pll_lock_in                (pll_lock_out)                  // input wire pll_lock_in
    
);

endmodule
`default_nettype wire

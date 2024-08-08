//------------------------------------------------------------------------
// mipi_phy.v
//
// This PHY is a wrapper for the MIPI CSI-2 Receiver Subsystem IP. We port 
// out important signals and busses required by the state machine within image_if.v.
//
// MIPI CSI-2 Receiver Subsystem IP configuration for 1080p 30FPS mode used in this design:
// Lanes=2, Line-rate=420, DataType=Raw10, Pixels Per Clock=4
//
//
// Copyright (c) 2022 Opal Kelly Incorporated
//------------------------------------------------------------------------

`default_nettype none

module mipi_phy (
    input  wire        video_aclk,
    input  wire        reset,
    input  wire        ctrl_core_en,
    input  wire        dphy_clk_200M,
    // Camera MIPI interface
    input  wire [0:0]  mipi_phy_if_clk_p,
    input  wire [0:0]  mipi_phy_if_clk_n,
    input  wire [1:0]  mipi_phy_if_data_p,
    input  wire [1:0]  mipi_phy_if_data_n,

    // Deserialized outputs
    output wire [39:0] pix_data,   // 10 bits per pixel, 4 pixels at a time
    output wire        line_valid, // Pixel data is valid
    output wire [9:0]  sync_word,  // useful for debug, view sync word 4
    output wire        sync_sof,
    output wire        sync_sol,
    output wire        sync_eol,
    output wire        sync_eof,
    output wire        sync_error  // Invalid sync word detected, error
);

wire        frame_rcvd_pulse_out;
wire        errsotsynchs_intr;
wire [1:0]  video_out_tuser;
wire        video_out_tlast;
wire        video_out_tvalid;
wire [39:0] video_out_tdata;


assign sync_error = errsotsynchs_intr;
assign sync_sof = video_out_tuser[0];
assign sync_eof = frame_rcvd_pulse_out;
assign sync_eol = video_out_tlast;
assign line_valid = video_out_tvalid;
assign pix_data = video_out_tdata;

mipi_csi2_rx_subsystem_0 mipi_phy (
    
  // The following signals are useful for debugging the interface
  .rxbyteclkhs          (),                        // output wire rxbyteclkhs
  .system_rst_out       (),                        // output wire system_rst_out
  .pll_lock_out         (),                        // output wire pll_lock_out
  .ctrl_dis_in_prgs     (),                        // output wire ctrl_dis_in_prgs
  .errsoths_intr        (),                        // output wire errsoths_intr
  .cl_stopstate_intr    (),                        // output wire cl_stopstate_intr
  .dl0_stopstate_intr   (),                        // output wire dl0_stopstate_intr
  .dl1_stopstate_intr   (),                        // output wire dl1_stopstate_intr
  .crc_status_intr      (),                        // output wire crc_status_intr
  .ecc_status_intr      (),                        // output wire [1 : 0] ecc_status_intr
  .linebuffer_full      (),                        // output wire linebuffer_full
  
  // active_lanes was introduced in Vivado v2022.1,  MIPI CSI-2 Rx Subsystem Version 5.1 (Rev. 5)
  // active_lanes is commented out within this project to be compatible with past versions of Vivado, 
  // but will produce a critical warning in v2022.1 and later about unconnected pin active_lanes, this 
  // critical warning can be ignored.
  //.active_lanes       (2'b11),                   // input wire [1 : 0] active_lanes

  .frame_rcvd_pulse_out (frame_rcvd_pulse_out),    // output wire frame_rcvd_pulse_out
  .errsotsynchs_intr    (errsotsynchs_intr),       // output wire errsotsynchs_intr
  
  .ctrl_core_en         (ctrl_core_en),            // input wire ctrl_core_en
  .dphy_clk_200M        (dphy_clk_200M),           // input wire dphy_clk_200M
  .video_aclk           (video_aclk),              // input wire video_aclk
  .video_aresetn        (~reset),                  // input wire video_aresetn
  .video_out_tdata      (video_out_tdata),         // output wire [39 : 0] video_out_tdata
  .video_out_tdest      (),                        // output wire [9 : 0] video_out_tdest
  .video_out_tlast      (video_out_tlast),         // output wire video_out_tlast
  .video_out_tready     (1'b1),                    // input wire video_out_tready
  .video_out_tuser      (video_out_tuser),         // output wire [1 : 0] video_out_tuser
  .video_out_tvalid     (video_out_tvalid),        // output wire video_out_tvalid
  
  .mipi_phy_if_clk_n    (mipi_phy_if_clk_n),       // input wire mipi_phy_if_clk_n
  .mipi_phy_if_clk_p    (mipi_phy_if_clk_p),       // input wire mipi_phy_if_clk_p
  .mipi_phy_if_data_n   (mipi_phy_if_data_n),      // input wire [1 : 0] mipi_phy_if_data_n
  .mipi_phy_if_data_p   (mipi_phy_if_data_p)       // input wire [1 : 0] mipi_phy_if_data_p
);

endmodule
`default_nettype wire

//------------------------------------------------------------------------
// okcamera - Top-level SZG-MIPI-8320(Pcam connected to Camera 1, 2, and 3) connected 
//            to port A + XEM8320 camera HDL
//
// Clocks:
//    sys_clk_p/n       - 100 MHz differential input clock
//    ddr4_clkp/n       - 100 MHz differential input clock
//    clk_ti            - 100.8 MHz host-interface clock provided by okHost
//    memif_clk         - 333.33 MHz Memory interface clock provided by MIG interface
//    dphy_clk_200M     - 200 MHz Clock for MIPI CSI-2 RX Subsystem. Provided by PLL.
//    pix_clk           - 100 MHz Clock for MIPI CSI-2 RX Subsystem video interface. Provided by PLL.
//    
//
// Host Interface registers:
// WireIn 0x00
//     0 - MIG RESET (active high)
//     3 - Logic RESET (active high)
//     6 - I2C controller RESET (active high)
//     7 - MIPI CSI-2 RX Subsystem core enable (active high)
//     8 - MIPI CSI-2 RX Subsystem core RESET (active high)
// WireIn 0x01
//   7:0 - I2C input data
// WireIn 03:02 - img_size[31:0]
// WireIn 0x04
//   9:0 - Programmable empty threshold
//    10 - Use programmable empty threshold
// WireIn 0x05
//   9:0 - Programmable full threshold
//    10 - Use programmable full threshold
// WireIn 0x06
//     0 - Pcam power enable
//
// WireOut 0x20
//  10:0 - Image buffer read count
// WireOut 0x22
//  15:0 - I2C data output
// WireOut 0x23
//   7:0 - Missed frame count
//     8 - Address buffer empty indicator.
// WireOut 0x24
//  10:0 - Buffer address FIFO count (Number of stored frames)
// WireOut 0x3E - Capability
// WireOut 0x3F - Version
//
// TriggerIn 0x40
//     0 - Start Readout
//     1 - Readout Done
// TriggerIn 0x42
//     0 - I2C start
//     1 - I2C memory start
//     2 - I2C memory write
//     3 - I2C memory read
// TriggerOut 0x60  (pix_clk)
//     0 - Frame available
// TriggerOut 0x61  (clk_ti)
//     0 - I2C done
//
// PipeOut 0xA0 - Image data readout port
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//
// Copyright (c) 2004-2022 Opal Kelly Incorporated
//------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none

module szg_mipi_8320 # (
    parameter SIMULATION            = "FALSE"
)
(
    input  wire [4:0]  okUH,
    output wire [2:0]  okHU,
    inout  wire [31:0] okUHU,
    inout  wire        okAA,
    
    output wire [5:0]  led,
    
    //Clocks
    input  wire        ddr4_clk_p,  // 100 MHz
    input  wire        ddr4_clk_n,
    
    input  wire        sys_clk_p,  // 100 MHz
    input  wire        sys_clk_n,
    
    //SZG-MIPI-8320 Camera 1
    inout  wire        pcam_sclk_1,
    inout  wire        pcam_sdata_1,
    output wire        pcam_power_en_1,
    input  wire [0:0]  mipi_phy_if_clk_p_1,
    input  wire [0:0]  mipi_phy_if_clk_n_1,
    input  wire [1:0]  mipi_phy_if_data_p_1,
    input  wire [1:0]  mipi_phy_if_data_n_1,
    
    //SZG-MIPI-8320 Camera 2
    inout  wire        pcam_sclk_2,
    inout  wire        pcam_sdata_2,
    output wire        pcam_power_en_2,
    input  wire [0:0]  mipi_phy_if_clk_p_2,
    input  wire [0:0]  mipi_phy_if_clk_n_2,
    input  wire [1:0]  mipi_phy_if_data_p_2,
    input  wire [1:0]  mipi_phy_if_data_n_2,
    
    //SZG-MIPI-8320 Camera 3
    inout  wire        pcam_sclk_3,
    inout  wire        pcam_sdata_3,
    output wire        pcam_power_en_3,
    input  wire [0:0]  mipi_phy_if_clk_p_3,
    input  wire [0:0]  mipi_phy_if_clk_n_3,
    input  wire [1:0]  mipi_phy_if_data_p_3,
    input  wire [1:0]  mipi_phy_if_data_n_3,
    
    //DDR Memory
    inout  wire [15:0] ddr4_dq,
    inout  wire [1:0]  ddr4_dqs_t,
    inout  wire [1:0]  ddr4_dqs_c,
    inout  wire [1:0]  ddr4_dm,
    output wire [0:0]  ddr4_act_n,
    output wire [16:0] ddr4_addr,
    output wire [1:0]  ddr4_ba,
    output wire [0:0]  ddr4_bg,
    output wire [0:0]  ddr4_ck_t,
    output wire [0:0]  ddr4_ck_c,
    output wire [0:0]  ddr4_cke,
    output wire [0:0]  ddr4_cs_n,
    output wire [0:0]  ddr4_odt,
    output wire        ddr4_reset_n
    );

// TOTAL_MEM represents the number of addressable memory locations. Equal to 2^(Width of c0_ddr4_app_addr) or 2^29
// There are two bytes per memory address. 
localparam TOTAL_MEM                 = 536870912;
localparam BYTES_PER_ADDR            = 2;
localparam ADDR_FIFO_PROG_FULL_MAX   = 1023;
localparam ADDR_FIFO_PROG_FULL_MIN   = 4;
localparam ADDR_FIFO_PROG_EMPTY_MAX  = 1023;
localparam ADDR_FIFO_PROG_EMPTY_MIN  = 6;

// HDL Version
// Top 8 bits signify the major version
// Bottom 8 bits used to indicate a minor version
localparam VERSION                   = 16'h02_00;
// Capability bits:
// Reserved for future use
localparam CAPABILITY                = 16'b0000_0000_0000_0000;

// USB Host Interface
wire  [112:0] okHE;
wire  [64:0]  okEH;

// Clock nets
wire          okClk;
wire          clk_ti;
wire          dphy_clk_200M;
wire          sys_clk_ibufds;
wire          pix_clk;
assign        clk_ti = okClk;

// MIG harnessing
wire          memif_clk;
wire          memif_rst;
wire          memif_calib_done;

// Memory interface
wire          memif_app_rdy;
wire          memif_app_en;
wire  [2:0]   memif_app_cmd;
wire  [28:0]  memif_app_addr;

wire  [127:0] memif_app_rd_data;
wire          memif_app_rd_data_end; 
wire          memif_app_rd_data_valid;

wire          memif_app_wdf_rdy;
wire  [127:0] memif_app_wdf_data;

// MIG Read/Write Arbiter
wire          memarb_wdata_rd_en;
wire          memarb_app_wdf_wren;
wire          memarb_app_wdf_end;
wire  [31:0]  memarb_app_wdf_mask;

wire          memarb_wr_req;
wire  [28:0]  memarb_wr_addr;
wire          memarb_wr_ack;
wire          memarb_rd_req;
wire  [28:0]  memarb_rd_addr;
wire          memarb_rd_ack;

wire  [8:0]   wr_fifo_count;
wire  [8:0]   rd_fifo_count;
wire          imgif0_fifo_full;
wire          imgif0_fifo_empty;
wire          hstif0_fifo_full;
wire          hstif0_fifo_empty;
wire          hstif0_fifo_underflow;

// FrontPanel component nets
wire  [31:0]  ep00wire;
wire  [31:0]  ep02wire;
wire  [31:0]  ep03wire;
wire  [31:0]  ep04wire;
wire  [31:0]  ep05wire;
wire  [31:0]  ep06wire;
wire  [31:0]  ep07wire;
wire  [31:0]  ti40_mig;
wire  [31:0]  to60_pix;
wire          pipe_out_ep_read;
wire  [31:0]  pipe_out_datain;
wire  [10:0]  pipe_out_rd_count;

// I2C controller nets
reg   [31:0]  to61_clkti;
wire  [31:0]  ti42_clkti;
wire  [31:0]  memdin_i2c;
reg   [23:0]  memdout_i2c;

// Reset Chain
wire          i2cReset_async; 
wire          reset_async;
wire          reset_mig;
wire          reset_pixclk;
wire          reset_mipi;
wire          reset_clkti;
wire          reset_memif_clk; 
wire          i2cReset;
wire          reset_videoIF;

// MIPI CSI-2 RX Subsystem 
wire          ctrl_core_en;

// Coordinator
wire          imgctl_skipped;
wire  [15:0]  missed_count;
wire          imgif_trig_memclk;
wire          imgif_trig_pixclk;
wire          imgctl_framedone_memclk;
wire          imgctl_framedone_pixclk;
wire          imgctl_framewritten;
wire  [29:0]  input_buffer_addr;
wire  [29:0]  output_buffer_addr;
wire  [31:0]  img_size;
wire  [31:0]  img_size_memclk;
wire          output_buffer_start;
wire          output_buffer_done;
wire          output_buffer_behind;
wire  [10:0]  buff_addr_fifo_count;
wire          buff_addr_fifo_empty_comb;
wire          buff_addr_fifo_full_comb;
wire  [9:0]   buff_addr_prog_empty_setpt;
wire  [9:0]   buff_addr_prog_full_setpt;
wire          using_prog_full;
wire          using_prog_empty;

// I2C Controller signals
wire  [1:0]   I2CSelect;
reg           start_camera_1;
wire          done_camera_1;
reg           memstart_camera_1;
reg           memwrite_camera_1;
reg           memread_camera_1;
reg   [7:0]   memdin_camera_1;
wire  [7:0]   memdout_camera_1;
reg           start_camera_2;
wire          done_camera_2;
reg           memstart_camera_2;
reg           memwrite_camera_2;
reg           memread_camera_2;
reg   [7:0]   memdin_camera_2;
wire  [7:0]   memdout_camera_2;
reg           start_camera_3;
wire          done_camera_3;
reg           memstart_camera_3;
reg           memwrite_camera_3;
reg           memread_camera_3;
reg   [7:0]   memdin_camera_3;
wire  [7:0]   memdout_camera_3;

// asynchronous inputs from FrontPanel will get synced to the necessary clock domains
assign reset_async                = ep00wire[3];
assign i2cReset_async             = ep00wire[6];
assign reset_videoIF              = ep00wire[8];
// ep00wire[0] is reset_syspll is past devices that used the MIG to generate output clocks.
// This has been renamed in this implementation to better embody its purpose.
assign reset_mig                  = ep00wire[0]; 

// MIPI CSI-2 RX Subsystem control signal
assign ctrl_core_en               = ep00wire[7];

// Control signals for imgbuf_coordinator
assign output_buffer_done         = ti40_mig[1];
assign img_size                   = {ep03wire[15:0], ep02wire[15:0]};
assign buff_addr_prog_empty_setpt = ep04wire[9:0];
assign using_prog_empty           = ep04wire[10];
assign buff_addr_prog_full_setpt  = ep05wire[9:0];
assign using_prog_full            = ep05wire[10];

// Indication from image_if to FrontPanel
assign to60_pix[0]                = imgctl_framedone_pixclk;

// Outputs to the PCB
assign pcam_power_en_1            = ep06wire[0];
assign pcam_power_en_2            = ep06wire[0];
assign pcam_power_en_3            = ep06wire[0];
assign led                        = {hstif0_fifo_full, hstif0_fifo_empty, imgif0_fifo_full, imgif0_fifo_empty, buff_addr_fifo_full_comb, buff_addr_fifo_empty_comb};

IBUFDS sys_clk_ibufds_i (
    .O                          (sys_clk_ibufds),       	  // output
    .I                          (sys_clk_p),            	  // input (p)
    .IB                         (sys_clk_n)             	  // input (n)
);

clk_wiz_fabric clk_wiz_fabric_i(
    .clk_out1                   (dphy_clk_200M),              // output (200Mhz)
    .clk_out2                   (pix_clk),                    // output (100Mhz)
    .locked                     (),                           // output 
    .clk_in1                    (sys_clk_ibufds)              // input     
);

// Create RESETs that deassert synchronous to specific clocks
sync_reset sync_reset1 (.clk(memif_clk), .async_reset(reset_async),    .sync_reset(reset_memif_clk));
sync_reset sync_reset2 (.clk(clk_ti),    .async_reset(reset_async),    .sync_reset(reset_clkti));
sync_reset sync_reset3 (.clk(clk_ti),    .async_reset(i2cReset_async), .sync_reset(i2cReset));
sync_reset sync_reset4 (.clk(pix_clk),   .async_reset(reset_async),    .sync_reset(reset_pixclk));
sync_reset sync_reset5 (.clk(pix_clk),   .async_reset(reset_videoIF),  .sync_reset(reset_mipi));

// Sync wires and buses to various clock domains
sync_trig sync_imgctl_framedone(
    .clk_i                      (pix_clk),                    // input
    .clk_o                      (memif_clk),                  // input
    .rst_i                      (reset_pixclk),               // input
    .rst_o                      (reset_memif_clk),            // input
    .trig_i                     (imgctl_framedone_pixclk),    // input
    .trig_o                     (imgctl_framedone_memclk)     // output
);

sync_trig sync_imgif_trig(
    .clk_i                      (memif_clk),                  // input
    .clk_o                      (pix_clk),                    // input
    .rst_i                      (reset_memif_clk),            // input
    .rst_o                      (reset_pixclk),               // input
    .trig_i                     (imgif_trig_memclk),          // input
    .trig_o                     (imgif_trig_pixclk)           // output
);

sync_bus # (
    .N                          (32)
) sync_img_size (
    .clk_src                    (clk_ti),                     // input
    .clk_dst                    (memif_clk),                  // input
    .reset                      (reset_clkti),                // input
    .bus_src                    (img_size),                   // input  [31:0]
    .bus_dst                    (img_size_memclk)             // output [31:0]
);

// The I2C controller is used to configure the SZG-Camera. You can read about this
// controller and its usage at our I2CController repository on our opalkelly-opensource
// GitHub account.
assign I2CSelect = ep07wire[1:0];
localparam
    camera_1 = 2'b00,
    camera_2 = 2'b01,
    camera_3 = 2'b10;

always @(*) begin
    // Default signals so they are always driven
    start_camera_1    = 1'b0;
    memstart_camera_1 = 1'b0;
    memwrite_camera_1 = 1'b0;
    memread_camera_1  = 1'b0;
    memdin_camera_1   = 8'h00;

    start_camera_2    = 1'b0;
    memstart_camera_2 = 1'b0;
    memwrite_camera_2 = 1'b0;
    memread_camera_2  = 1'b0;
    memdin_camera_2   = 8'h00;

    start_camera_3    = 1'b0;
    memstart_camera_3 = 1'b0;
    memwrite_camera_3 = 1'b0;
    memread_camera_3  = 1'b0;
    memdin_camera_3   = 8'h00;

    memdout_i2c[7:0]  = 8'h00;
    to61_clkti[0]     = 1'b0;

    // Change signal values based on I2CSelect
    case (I2CSelect)
        camera_1  : begin
            start_camera_1    = ti42_clkti[0];
            to61_clkti[0]     = done_camera_1;
            memstart_camera_1 = ti42_clkti[1];
            memwrite_camera_1 = ti42_clkti[2];
            memread_camera_1  = ti42_clkti[3];
            memdin_camera_1   = memdin_i2c[7:0];
            memdout_i2c[7:0]  = memdout_camera_1;
        end
        camera_2  : begin
            start_camera_2    = ti42_clkti[0];
            to61_clkti[0]     = done_camera_2;
            memstart_camera_2 = ti42_clkti[1];
            memwrite_camera_2 = ti42_clkti[2];
            memread_camera_2  = ti42_clkti[3];
            memdin_camera_2   = memdin_i2c[7:0];
            memdout_i2c[7:0]  = memdout_camera_2;
        end
        camera_3  : begin
            start_camera_3    = ti42_clkti[0];
            to61_clkti[0]     = done_camera_3;
            memstart_camera_3 = ti42_clkti[1];
            memwrite_camera_3 = ti42_clkti[2];
            memread_camera_3  = ti42_clkti[3];
            memdin_camera_3   = memdin_i2c[7:0];
            memdout_i2c[7:0]  = memdout_camera_3;
        end
    endcase
end
i2cController #(
    .CLOCK_STRETCH_SUPPORT      (0),
    .CLOCK_DIVIDER              (16'h114)
) i2c_ctrl1 (
    .clk                        (clk_ti),                     // input
    .reset                      (i2cReset),                   // input
    .start                      (start_camera_1),             // input
    .done                       (done_camera_1),              // output
    .memclk                     (clk_ti),                     // input
    .memstart                   (memstart_camera_1),          // input
    .memwrite                   (memwrite_camera_1),          // input
    .memread                    (memread_camera_1),           // input
    .memdin                     (memdin_camera_1),            // input  [7:0]
    .memdout                    (memdout_camera_1),           // output [7:0]
    .i2c_sclk                   (pcam_sclk_1),                // inout
    .i2c_sdat                   (pcam_sdata_1)                // inout
);
i2cController #(
    .CLOCK_STRETCH_SUPPORT      (0),
    .CLOCK_DIVIDER              (16'h114)
) i2c_ctrl2 (
    .clk                        (clk_ti),                     // input
    .reset                      (i2cReset),                   // input
    .start                      (start_camera_2),             // input
    .done                       (done_camera_2),              // output
    .memclk                     (clk_ti),                     // input
    .memstart                   (memstart_camera_2),          // input
    .memwrite                   (memwrite_camera_2),          // input
    .memread                    (memread_camera_2),           // input
    .memdin                     (memdin_camera_2),            // input  [7:0]
    .memdout                    (memdout_camera_2),           // output [7:0]
    .i2c_sclk                   (pcam_sclk_2),                // inout
    .i2c_sdat                   (pcam_sdata_2)                // inout
);
i2cController #(
    .CLOCK_STRETCH_SUPPORT      (0),
    .CLOCK_DIVIDER              (16'h114)
) i2c_ctrl3 (
    .clk                        (clk_ti),                     // input
    .reset                      (i2cReset),                   // input
    .start                      (start_camera_3),             // input
    .done                       (done_camera_3),              // output
    .memclk                     (clk_ti),                     // input
    .memstart                   (memstart_camera_3),          // input
    .memwrite                   (memwrite_camera_3),          // input
    .memread                    (memread_camera_3),           // input
    .memdin                     (memdin_camera_3),            // input  [7:0]
    .memdout                    (memdout_camera_3),           // output [7:0]
    .i2c_sclk                   (pcam_sclk_3),                // inout
    .i2c_sdat                   (pcam_sdata_3)                // inout
);

imgbuf_coordinator # (
    .TOTAL_MEM                  (TOTAL_MEM),
    .ADDR_FIFO_PROG_FULL_MAX    (ADDR_FIFO_PROG_FULL_MAX),
    .ADDR_FIFO_PROG_FULL_MIN    (ADDR_FIFO_PROG_FULL_MIN),
    .ADDR_FIFO_PROG_EMPTY_MAX   (ADDR_FIFO_PROG_EMPTY_MAX),
    .ADDR_FIFO_PROG_EMPTY_MIN   (ADDR_FIFO_PROG_EMPTY_MIN)
) coord0 (
    .clk                        (memif_clk),                  // input
    .rst                        (reset_memif_clk),            // input
    .missed_count               (missed_count),               // output [15:0]
    .imgif_trig                 (imgif_trig_memclk),          // output
    .imgctl_framedone           (imgctl_framedone_memclk),    // input
    .imgctl_framewritten        (imgctl_framewritten),        // input
    .input_buffer_addr          (input_buffer_addr),          // output [29:0]
    .output_buffer_addr         (output_buffer_addr),         // output [29:0]
    .img_size                   (img_size_memclk),            // input  [23:0]
    .output_buffer_trig         (ti40_mig[0]),                // input
    .output_buffer_start        (output_buffer_start),        // output
    .output_buffer_done         (output_buffer_done),         // input
    .output_buffer_behind       (output_buffer_behind),       // output
    .buff_addr_fifo_count       (buff_addr_fifo_count),       // output [10:0]
    .buff_addr_prog_empty_setpt (buff_addr_prog_empty_setpt), // input  [9:0]
    .buff_addr_prog_full_setpt  (buff_addr_prog_full_setpt),  // input  [9:0]
    .buff_addr_fifo_empty_comb  (buff_addr_fifo_empty_comb),  // output
    .buff_addr_fifo_full_comb   (buff_addr_fifo_full_comb),   // output
    .use_prog_empty             (using_prog_empty),           // input
    .use_prog_full              (using_prog_full),            // input
    .memif_calib_done           (memif_calib_done)            // input
);

image_if_wrapper imgif0(
    .clk                        (pix_clk),                    // input
    .reset                      (reset_pixclk),               // input
    .reset_mipi                 (reset_mipi),                 // input
    .ctrl_core_en               (ctrl_core_en),               // input
    .dphy_clk_200M              (dphy_clk_200M),              // input
    
    // MIPI interface camera 1
    .mipi_phy_if_clk_p_1        (mipi_phy_if_clk_p_1),        // input
    .mipi_phy_if_clk_n_1        (mipi_phy_if_clk_n_1),        // input
    .mipi_phy_if_data_p_1       (mipi_phy_if_data_p_1),       // input  [1:0]
    .mipi_phy_if_data_n_1       (mipi_phy_if_data_n_1),       // input  [1:0]
    
    // MIPI interface camera 2
    .mipi_phy_if_clk_p_2        (mipi_phy_if_clk_p_2),        // input
    .mipi_phy_if_clk_n_2        (mipi_phy_if_clk_n_2),        // input
    .mipi_phy_if_data_p_2       (mipi_phy_if_data_p_2),       // input  [1:0]
    .mipi_phy_if_data_n_2       (mipi_phy_if_data_n_2),       // input  [1:0]
    
    // MIPI interface camera 3
    .mipi_phy_if_clk_p_3        (mipi_phy_if_clk_p_3),        // input
    .mipi_phy_if_clk_n_3        (mipi_phy_if_clk_n_3),        // input
    .mipi_phy_if_data_p_3       (mipi_phy_if_data_p_3),       // input  [1:0]
    .mipi_phy_if_data_n_3       (mipi_phy_if_data_n_3),       // input  [1:0]
    
    .trigger                    (imgif_trig_pixclk),          // input
    .frame_done                 (imgctl_framedone_pixclk),    // output
    
    .mem_clk                    (memif_clk),                  // input
    .mem_reset                  (reset_memif_clk),            // input
    
    .start_addr                 (input_buffer_addr),          // input  [29:0]
    .frame_written              (imgctl_framewritten),        // output
    
    .mem_wr_req                 (memarb_wr_req),              // output
    .mem_wr_addr                (memarb_wr_addr),             // output [28:0]
    .mem_wr_ack                 (memarb_wr_ack),              // input
    
    .fifo_rd_data_count         (wr_fifo_count),              // output [8:0]
    .mem_wdata_rd_en            (memarb_wdata_rd_en),         // input
    .mem_wdf_data               (memif_app_wdf_data),         // output [127:0]
    .fifo_full                  (imgif0_fifo_full),           // output
    .fifo_empty                 (imgif0_fifo_empty)           // output
);
    
host_if hstif0(
    .clk                        (memif_clk),                  // input
    .clk_ti                     (clk_ti),                     // input
    .reset_clk                  (reset_memif_clk),            // input
    .readout_start              (output_buffer_start),        // input
    .readout_done               (output_buffer_done),         // input
    .readout_addr               (output_buffer_addr),         // input  [29:0]
    .readout_count              (img_size_memclk),            // input  [31:0]
    
    .mem_rd_req                 (memarb_rd_req),              // output
    .mem_rd_addr                (memarb_rd_addr),             // output [28:0]
    .mem_rd_ack                 (memarb_rd_ack),              // input

    .mem_rd_data                (memif_app_rd_data),          // input  [127:0]
    .mem_rd_data_valid          (memif_app_rd_data_valid),    // input
    .mem_rd_data_end            (memif_app_rd_data_end),      // input

    .ob_count                   (rd_fifo_count),              // output [8:0]

    .ob_rd_en                   (pipe_out_ep_read),           // input
    .pofifo0_rd_count           (pipe_out_rd_count),          // output [10:0]
    .pofifo0_dout               (pipe_out_datain),            // output [31:0]
    .pofifo0_underflow          (hstif0_fifo_underflow),      // output
    .pofifo0_full               (hstif0_fifo_full),           // output
    .pofifo0_empty              (hstif0_fifo_empty)           // output
);

mem_arbiter memarb0(
    .clk                        (memif_clk),                  // input
    .reset                      (memif_rst),                  // input
    .calib_done                 (memif_calib_done),           // input
    
    .app_rdy                    (memif_app_rdy),              // input
    .app_en                     (memif_app_en),               // output
    .app_cmd                    (memif_app_cmd),              // output [2:0]
    .app_addr                   (memif_app_addr),             // output [28:0]
    
    .app_wdf_rdy                (memif_app_wdf_rdy),          // input
    .app_wdf_wren               (memarb_app_wdf_wren),        // output
    .app_wdf_end                (memarb_app_wdf_end),         // output
    .app_wdf_mask               (memarb_app_wdf_mask),        // output [15:0]
    
    .wdata_rd_en                (memarb_wdata_rd_en),         // output
    
    .wr_fifo_count              (wr_fifo_count),              // input  [8:0]
    .rd_fifo_count              (rd_fifo_count),              // input  [8:0]
    
    .wr_req                     (memarb_wr_req),              // input
    .wr_ack                     (memarb_wr_ack),              // output
    .wr_addr                    (memarb_wr_addr),             // input  [28:0]
    .rd_req                     (memarb_rd_req),              // input
    .rd_ack                     (memarb_rd_ack),              // output
    .rd_addr                    (memarb_rd_addr)              // input  [28:0]
);

// MIG User Interface instantiation
ddr4_0 ddr4_128_16_mig (
    .c0_init_calib_complete     (memif_calib_done),           // output wire c0_init_calib_complete
    .dbg_clk                    (),                           // output wire dbg_clk
    .c0_sys_clk_p               (ddr4_clk_p),                 // input  wire c0_sys_clk_p
    .c0_sys_clk_n               (ddr4_clk_n),                 // input  wire c0_sys_clk_n
    .dbg_bus                    (),                           // output wire [511 : 0] dbg_bus
    .c0_ddr4_adr                (ddr4_addr),                  // output wire [16 : 0] c0_ddr4_adr
    .c0_ddr4_ba                 (ddr4_ba),                    // output wire [1 : 0] c0_ddr4_ba
    .c0_ddr4_cke                (ddr4_cke),                   // output wire [0 : 0] c0_ddr4_cke
    .c0_ddr4_cs_n               (ddr4_cs_n),                  // output wire [0 : 0] c0_ddr4_cs_n
    .c0_ddr4_dm_dbi_n           (ddr4_dm),                    // inout  wire [1 : 0] c0_ddr4_dm_dbi_n
    .c0_ddr4_dq                 (ddr4_dq),                    // inout  wire [15 : 0] c0_ddr4_dq
    .c0_ddr4_dqs_c              (ddr4_dqs_c),                 // inout  wire [1 : 0] c0_ddr4_dqs_c
    .c0_ddr4_dqs_t              (ddr4_dqs_t),                 // inout  wire [1 : 0] c0_ddr4_dqs_t
    .c0_ddr4_odt                (ddr4_odt),                   // output wire [0 : 0] c0_ddr4_odt
    .c0_ddr4_bg                 (ddr4_bg),                    // output wire [0 : 0] c0_ddr4_bg
    .c0_ddr4_reset_n            (ddr4_reset_n),               // output wire c0_ddr4_reset_n
    .c0_ddr4_act_n              (ddr4_act_n),                 // output wire c0_ddr4_act_n
    .c0_ddr4_ck_c               (ddr4_ck_c),                  // output wire [0 : 0] c0_ddr4_ck_c
    .c0_ddr4_ck_t               (ddr4_ck_t),                  // output wire [0 : 0] c0_ddr4_ck_t
    
    .c0_ddr4_ui_clk             (memif_clk),                  // output wire c0_ddr4_ui_clk
    .c0_ddr4_ui_clk_sync_rst    (memif_rst),                  // output wire c0_ddr4_ui_clk_sync_rst
    
    .c0_ddr4_app_en             (memif_app_en),               // input  wire c0_ddr4_app_en
    .c0_ddr4_app_hi_pri         (1'b0),                       // input  wire c0_ddr4_app_hi_pri
    .c0_ddr4_app_wdf_end        (memarb_app_wdf_end),         // input  wire c0_ddr4_app_wdf_end
    .c0_ddr4_app_wdf_wren       (memarb_app_wdf_wren),        // input  wire c0_ddr4_app_wdf_wren
    .c0_ddr4_app_rd_data_end    (memif_app_rd_data_end),      // output wire c0_ddr4_app_rd_data_end
    .c0_ddr4_app_rd_data_valid  (memif_app_rd_data_valid),    // output wire c0_ddr4_app_rd_data_valid
    .c0_ddr4_app_rdy            (memif_app_rdy),              // output wire c0_ddr4_app_rdy
    .c0_ddr4_app_wdf_rdy        (memif_app_wdf_rdy),          // output wire c0_ddr4_app_wdf_rdy
    .c0_ddr4_app_addr           (memif_app_addr),             // input  wire [28 : 0] c0_ddr4_app_addr
    .c0_ddr4_app_cmd            (memif_app_cmd),              // input  wire [2 : 0] c0_ddr4_app_cmd
    .c0_ddr4_app_wdf_data       (memif_app_wdf_data),         // input  wire [127 : 0] c0_ddr4_app_wdf_data
    .c0_ddr4_app_wdf_mask       (memarb_app_wdf_mask),        // input  wire [15 : 0] c0_ddr4_app_wdf_mask
    .c0_ddr4_app_rd_data        (memif_app_rd_data),          // output wire [127 : 0] c0_ddr4_app_rd_data
    
    .sys_rst                    (reset_mig)                   // input  wire sys_rst
);

// Instantiate the okHost and connect endpoints.
wire [65*10-1:0]  okEHx;
okHost okHI(
    .okUH(okUH),
    .okHU(okHU),
    .okUHU(okUHU),
    .okAA(okAA),
    .okClk(okClk),
    .okHE(okHE), 
    .okEH(okEH)
);

okWireOR # (.N(10)) wireOR (okEH, okEHx);

okWireIn     wi00  (.okHE(okHE),                             .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn     wi01  (.okHE(okHE),                             .ep_addr(8'h01), .ep_dataout(memdin_i2c));
okWireIn     wi02  (.okHE(okHE),                             .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireIn     wi03  (.okHE(okHE),                             .ep_addr(8'h03), .ep_dataout(ep03wire));
okWireIn     wi04  (.okHE(okHE),                             .ep_addr(8'h04), .ep_dataout(ep04wire));
okWireIn     wi05  (.okHE(okHE),                             .ep_addr(8'h05), .ep_dataout(ep05wire));

okWireIn     wi06  (.okHE(okHE),                             .ep_addr(8'h06), .ep_dataout(ep06wire));
okWireIn     wi07  (.okHE(okHE),                             .ep_addr(8'h07), .ep_dataout(ep07wire));

okTriggerIn  ti40b (.okHE(okHE),                             .ep_addr(8'h40), .ep_clk(memif_clk), .ep_trigger(ti40_mig));
okTriggerIn  ti42  (.okHE(okHE),                             .ep_addr(8'h42), .ep_clk(clk_ti),    .ep_trigger(ti42_clkti));

okTriggerOut to60  (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'h60), .ep_clk(pix_clk),  .ep_trigger(to60_pix));
okTriggerOut to61  (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]), .ep_addr(8'h61), .ep_clk(clk_ti),   .ep_trigger(to61_clkti));

okPipeOut    po0   (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]), .ep_addr(8'ha0), .ep_read(pipe_out_ep_read),   .ep_datain(pipe_out_datain));

okWireOut    wo20  (.okHE(okHE), .okEH(okEHx[ 3*65 +: 65 ]), .ep_addr(8'h20), .ep_datain({21'b0, pipe_out_rd_count}));
okWireOut    wo21  (.okHE(okHE), .okEH(okEHx[ 4*65 +: 65 ]), .ep_addr(8'h21), .ep_datain(32'b0));
okWireOut    wo22  (.okHE(okHE), .okEH(okEHx[ 5*65 +: 65 ]), .ep_addr(8'h22), .ep_datain({24'b0, memdout_i2c}));
okWireOut    wo23  (.okHE(okHE), .okEH(okEHx[ 6*65 +: 65 ]), .ep_addr(8'h23), .ep_datain({23'b0, ~buff_addr_fifo_empty_comb, missed_count[7:0]}));
okWireOut    wo24  (.okHE(okHE), .okEH(okEHx[ 7*65 +: 65 ]), .ep_addr(8'h24), .ep_datain(buff_addr_fifo_count));
okWireOut    wo3e  (.okHE(okHE), .okEH(okEHx[ 8*65 +: 65 ]), .ep_addr(8'h3e), .ep_datain({16'b0, CAPABILITY}));
okWireOut    wo3f  (.okHE(okHE), .okEH(okEHx[ 9*65 +: 65 ]), .ep_addr(8'h3f), .ep_datain({16'b0, VERSION}));

endmodule
 
`default_nettype wire

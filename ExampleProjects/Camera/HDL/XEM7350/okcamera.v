//------------------------------------------------------------------------
// okcamera - Top-level EVB1006 camera HDL
//
// Clocks:
//    SYS_CLKP/N - 200 MHz differential input clock
//    CLK_TI     - 100.8 MHz host-interface clock provided by okHost
//    CLK0       - Memory interface clock provided by MEM_IF
//    CLK_PIX    - 96 MHz single-ended input clock from image sensor
//
//
// Host Interface registers:
// WireIn 0x00
//     0 - System PLL RESET (active high)
//     1 - Image sensor RESET (active high)
//     2 - Pixel DCM RESET (active high)
//     3 - Logic RESET (active high)
//     5 - Image packing mode (0=8-bit, 1=16-bit)
// WireIn 0x01
//   7:0 - I2C input data
// WireIn 03:02 - image_size[23:0]
// WireIn 0x04
//   9:0 - Programmable empty threshold
//    10 - Use programmable empty threshold
// WireIn 0x05
//   9:0 - Programmable full threshold
//    10 - Use programmable full threshold
//
// WireOut 0x20
//  10:0 - Image buffer read count
// WireOut 0x22
//  15:0 - I2C data output
// WireOut 0x23
//   7:0 - Skipped frame count
//     8 - Frame buffer available
// WireOut 0x24
//  10:0 - Stored frame count
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
// TriggerOut 0x61  (i2c_clk)
//     0 - I2C done
//
// PipeOut 0xA0 - Image readout port
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2009 Opal Kelly Incorporated
// $Rev: 165 $ $Date: 2012-06-15 17:39:44 -0500 (Fri, 15 Jun 2012) $
//------------------------------------------------------------------------
`timescale 1ns/1ps
// Don't use this because the Xilinx MIG generates code that doesn't declare
// net types on module inputs, so it's not compliant.~
//`default_nettype none

module evb1006 # (
	parameter SIMULATION            = "FALSE"
)
(
	input  wire [4:0]  okUH,
	output wire [2:0]  okHU,
	inout  wire [31:0] okUHU,
	inout  wire        okAA,
	
	output wire [3:0]  led,
	
	//Clocks
	input  wire        sys_clkp,  // 200 MHz
	input  wire        sys_clkn,
	
	//EVB1005
	inout  wire        pix_sdata,
	output wire        pix_sclk,
	output wire        pix_trigger,
	output wire        pix_reset,

	output wire        pix_extclk,
	input  wire        pix_strobe,
	input  wire        pix_clk,
	input  wire        pix_lv,
	input  wire        pix_fv,
	input  wire [11:0] pix_data,
	
	//DDR Memory
	inout  wire [15:0] ddr3_dq,
	output wire [14:0] ddr3_addr,
	output wire [2:0]  ddr3_ba,
	output wire [0:0]  ddr3_ck_p,
	output wire [0:0]  ddr3_ck_n,
	output wire [0:0]  ddr3_cke,
	output wire [0:0]  ddr3_cs_n,
	output wire        ddr3_cas_n,
	output wire        ddr3_ras_n,
	output wire        ddr3_we_n,
	output wire [0:0]  ddr3_odt,
	output wire [1:0]  ddr3_dm,
	inout  wire [1:0]  ddr3_dqs_p,
	inout  wire [1:0]  ddr3_dqs_n,
	output wire        ddr3_reset_n
	);

localparam BLOCK_SIZE                = 128/4;
localparam TOTAL_MEM                 = 536870912;
localparam BYTES_PER_ADDR            = 2;
localparam ADDR_FIFO_PROG_FULL_MAX   = 1023;
localparam ADDR_FIFO_PROG_FULL_MIN   = 4;
localparam ADDR_FIFO_PROG_EMPTY_MAX  = 1023;
localparam ADDR_FIFO_PROG_EMPTY_MIN  = 6;

// HDL Version
// Top 8 bits signify the major version
// Bottom 8 bits used to indicate a minor version
localparam VERSION    = 16'h02_00;
// Capability bits:
// Reserved for future use
localparam CAPABILITY = 16'b0000_0000_0000_0000;

// USB Host Interface
wire         okClk;
wire [112:0] okHE;
wire [64:0]  okEH;

wire         clk_ti;
assign       clk_ti = okClk;

wire [31:0]  hi_reg_addr;
wire         hi_reg_write;
wire [31:0]  hi_reg_write_data;
wire         hi_reg_read;
reg  [31:0]  hi_reg_read_data;

wire pll_lock;

// MIG harnessing
wire          memif_clk;
wire          memif_rst;
wire          memif_clk_ref;
wire          memif_mem_refclk;
wire          memif_freq_refclk;
wire          memif_sync_pulse;
wire          memif_rst_phaser_ref;
wire          memif_ref_dll_lock;
wire          memif_calib_done;

// Interfaces
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
wire  [15:0]  memarb_app_wdf_mask;

wire          memarb_wr_req;
wire  [28:0]  memarb_wr_addr;
wire          memarb_wr_ack;
wire          memarb_rd_req;
wire  [28:0]  memarb_rd_addr;
wire          memarb_rd_ack;

wire          imgif0_fifo_full;
wire          imgif0_fifo_empty;
wire          hstif0_fifo_full;
wire          hstif0_fifo_empty;
wire          hstif0_fifo_underflow;

//OK
wire [31:0] ep00wire, ep02wire, ep03wire, ep04wire, ep05wire;
wire [31:0] ti40_pix, ti40_mig, ti42_clkti;
wire [31:0] to60_pix, to61_clkti;
wire        pipe_out_ep_read;
wire [31:0] pipe_out_datain;
wire [10:0] pipe_out_rd_count;
reg         pipe_out_ready;
wire        imgctl_packing_mode;
wire        frame_done_t;
wire        clk_pix;
wire        i2c_sdat_out;
wire        i2c_drive;
wire        pix_extclk_o;

wire [8:0]  wr_fifo_count;
wire [8:0]  rd_fifo_count;


assign pix_trigger    = 1'b0;

assign pix_sdata = (i2c_drive) ? (i2c_sdat_out) : (1'bz);

ODDR #(
	.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
	.INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
	.SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
) i_pixext (
	.Q(pix_extclk),   // 1-bit DDR output
	.C(pix_extclk_o),   // 1-bit clock input
	   .CE(pll_lock), // 1-bit clock enable input
	   .D1(1'b1), // 1-bit data input (positive edge)
	   .D2(1'b0), // 1-bit data input (negative edge)
	.R(~pll_lock),   // 1-bit reset
	.S(1'b0)    // 1-bit set
);


// Reset Chain
wire reset_syspll;
wire reset_pixdcm;
wire reset_async;
wire reset_clkpix;
wire reset_clkti;
wire reset_memif_clk;

assign reset_syspll        =  ep00wire[0];
assign pix_reset           = ~ep00wire[1];
assign reset_pixdcm        =  ep00wire[2];
assign reset_async         =  ep00wire[3];
assign imgctl_packing_mode =  ep00wire[5];


// Create RESETs that deassert synchronous to specific clocks
sync_reset sync_reset0 (.clk(clk_pix),  .async_reset(reset_async),  .sync_reset(reset_clkpix));
sync_reset sync_reset1 (.clk(memif_clk),     .async_reset(reset_async),  .sync_reset(reset_memif_clk));
sync_reset sync_reset2 (.clk(clk_ti),   .async_reset(reset_async),  .sync_reset(reset_clkti));


// Coordinator
wire         imgctl_skipped;
reg  [7:0]   skipped_count;
wire [7:0]   skipped_count_clkti;
wire [15:0]  missed_count;
wire [7:0]   missed_count_clkti;
wire         imgif_trig_memclk;
wire         imgif_trig_pixclk;
wire         imgctl_framedone_memclk;
wire         imgctl_framedone_pixclk;
wire         imgctl_framewritten;
wire [29:0]  input_buffer_addr;
wire [29:0]  output_buffer_addr;
wire [23:0]  img_size;
wire [23:0]  img_size_memclk;
wire         output_buffer_start;
wire         output_buffer_done;
wire         output_buffer_behind;
wire [10:0]  buff_addr_fifo_count;
wire         buff_addr_fifo_empty_comb;
wire         buff_addr_fifo_full_comb;
wire [9:0]   buff_addr_prog_empty_setpt;
wire [9:0]   buff_addr_prog_full_setpt;
wire         using_prog_full;
wire         using_prog_empty;

assign output_buffer_done = ti40_mig[1];
assign img_size = {ep03wire[7:0], ep02wire[15:0]};

assign buff_addr_prog_empty_setpt = ep04wire[9:0];
assign using_prog_empty = ep04wire[10];
assign buff_addr_prog_full_setpt = ep05wire[9:0];
assign using_prog_full = ep05wire[10];

imgbuf_coordinator # (
	.TOTAL_MEM                (TOTAL_MEM),
	.ADDR_FIFO_PROG_FULL_MAX  (ADDR_FIFO_PROG_FULL_MAX),
	.ADDR_FIFO_PROG_FULL_MIN  (ADDR_FIFO_PROG_FULL_MIN),
	.ADDR_FIFO_PROG_EMPTY_MAX (ADDR_FIFO_PROG_EMPTY_MAX),
	.ADDR_FIFO_PROG_EMPTY_MIN (ADDR_FIFO_PROG_EMPTY_MIN)
) coord0 (
	.clk                        (memif_clk),
	.rst                        (reset_memif_clk),
	.missed_count               (missed_count),
	.imgif_trig                 (imgif_trig_memclk),
	.imgctl_framedone           (imgctl_framedone_memclk),
	.imgctl_framewritten        (imgctl_framewritten),
	.input_buffer_addr          (input_buffer_addr),
	.output_buffer_addr         (output_buffer_addr),
	.img_size                   (img_size_memclk),
	.output_buffer_trig         (ti40_mig[0]),
	.output_buffer_start        (output_buffer_start),
	.output_buffer_done         (output_buffer_done),
	.output_buffer_behind       (output_buffer_behind),
	.buff_addr_fifo_count       (buff_addr_fifo_count),
	.buff_addr_prog_empty_setpt (buff_addr_prog_empty_setpt),
	.buff_addr_prog_full_setpt  (buff_addr_prog_full_setpt),
	.buff_addr_fifo_empty_comb  (buff_addr_fifo_empty_comb),
	.buff_addr_fifo_full_comb   (buff_addr_fifo_full_comb),
	.use_prog_empty             (using_prog_empty),
	.use_prog_full              (using_prog_full),
	.memif_calib_done           (memif_calib_done)
);

sync_trig sync_imgctl_framedone(
	.clk_i (clk_pix),
	.clk_o (memif_clk),
	.rst_i (reset_clkpix),
	.rst_o (reset_memif_clk),
	.trig_i (imgctl_framedone_pixclk),
	.trig_o (imgctl_framedone_memclk)
);

sync_trig sync_imgif_trig(
	.clk_i (memif_clk),
	.clk_o (clk_pix),
	.rst_i (reset_memif_clk),
	.rst_o (reset_clkpix),
	.trig_i (imgif_trig_memclk),
	.trig_o (imgif_trig_pixclk)
);

assign led = ~{ using_prog_full, output_buffer_behind, buff_addr_fifo_full_comb, buff_addr_fifo_empty_comb };

sync_bus # (
	.N                (8)
) sync_skipped_count (
	.clk_src          (clk_pix),
	.clk_dst          (clk_ti),
	.reset            (reset_clkpix),
	.bus_src          (skipped_count),
	.bus_dst          (skipped_count_clkti)
);

sync_bus # (
	.N                (24)
) sync_img_size (
	.clk_src (clk_ti),
	.clk_dst (memif_clk),
	.reset   (reset_clkti),
	.bus_src (img_size),
	.bus_dst (img_size_memclk)
);

// Keep track of any skipped frames
// These are frames from the image sensor that we don't save in a buffer
// They differ from "missed frames", those that are saved in a buffer but
// are never read out due to a slow host.
always@ (posedge clk_pix) begin
	if (reset_clkpix) begin
		skipped_count <= 8'h00;
	end else begin
		if (imgctl_skipped) begin
			skipped_count <= skipped_count + 1'b1;
		end
	end
end

// Image Sensor Interface
assign to60_pix[0] = imgctl_framedone_pixclk;
assign to60_pix[31:1] = 0;

assign to61_clkti[31:1] = 0;

image_if imgif0(
		.clk                 (clk_pix),
		.reset               (reset_clkpix),
		.packing_mode        (imgctl_packing_mode),
	
		.pix_fv              (pix_fv),
		.pix_lv              (pix_lv),
		.pix_data            (pix_data),
		
		.trigger             (imgif_trig_pixclk),
		.start_addr          (input_buffer_addr),
		.frame_done          (imgctl_framedone_pixclk),
		.frame_written       (imgctl_framewritten),
		.skipped             (imgctl_skipped),
		
		.mem_clk             (memif_clk),
		.mem_reset           (reset_memif_clk),
		
		.mem_wr_req          (memarb_wr_req),
		.mem_wr_addr         (memarb_wr_addr),
		.mem_wr_ack          (memarb_wr_ack),
	
		.fifo_rd_data_count  (wr_fifo_count),
		.mem_wdata_rd_en     (memarb_wdata_rd_en),
		.mem_wdf_data        (memif_app_wdf_data),
		.fifo_full           (imgif0_fifo_full),
		.fifo_empty          (imgif0_fifo_empty)
	);

host_if hstif0(
		.clk                (memif_clk),
		.clk_ti             (clk_ti),
		.reset_clk          (reset_memif_clk),
		.readout_start      (output_buffer_start),
		.readout_done       (output_buffer_done),
		.readout_addr       (output_buffer_addr),
		.readout_count      (img_size_memclk),
		
		.mem_rd_req         (memarb_rd_req),
		.mem_rd_addr        (memarb_rd_addr),
		.mem_rd_ack         (memarb_rd_ack),
	
		.mem_rd_data        (memif_app_rd_data),
		.mem_rd_data_valid  (memif_app_rd_data_valid),
		.mem_rd_data_end    (memif_app_rd_data_end),

		.ob_count           (rd_fifo_count),
	
		.ob_rd_en           (pipe_out_ep_read),
		.pofifo0_rd_count   (pipe_out_rd_count),
		.pofifo0_dout       (pipe_out_datain),
		.pofifo0_underflow  (hstif0_fifo_underflow),
		.pofifo0_full       (hstif0_fifo_full),
		.pofifo0_empty      (hstif0_fifo_empty)
	);



wire [31:0] memdin;
wire [7:0]  memdout;
i2cController i2c_ctrl0 (
		.clk          (clk_ti),
		.reset        (reset_clkti),
		.start        (ti42_clkti[0]),
		.done         (to61_clkti[0]),
		.divclk       (8'd100),
		.memclk       (clk_ti),
		.memstart     (ti42_clkti[1]),
		.memwrite     (ti42_clkti[2]),
		.memread      (ti42_clkti[3]),
		.memdin       (memdin[7:0]),
		.memdout      (memdout[7:0]),
		.i2c_sclk     (pix_sclk),
		.i2c_sdat_in  (pix_sdata),
		.i2c_sdat_out (i2c_sdat_out),
		.i2c_drive    (i2c_drive)
	);



mem_arbiter memarb0(
	.clk                   (memif_clk),
	.reset                 (memif_rst),
	.calib_done            (memif_calib_done),
	
	.app_rdy               (memif_app_rdy),
	.app_en                (memif_app_en),
	.app_cmd               (memif_app_cmd),
	.app_addr              (memif_app_addr),
	
	.app_wdf_rdy           (memif_app_wdf_rdy),
	.app_wdf_wren          (memarb_app_wdf_wren),
	.app_wdf_end           (memarb_app_wdf_end),
	.app_wdf_mask          (memarb_app_wdf_mask),
	
	.wdata_rd_en           (memarb_wdata_rd_en),

	.wr_fifo_count         (wr_fifo_count),
	.rd_fifo_count         (rd_fifo_count),
	
	.wr_req                (memarb_wr_req),
	.wr_ack                (memarb_wr_ack),
	.wr_addr               (memarb_wr_addr),
	.rd_req                (memarb_rd_req),
	.rd_ack                (memarb_rd_ack),
	.rd_addr               (memarb_rd_addr)
	);


mem_if # (
		// MIG Parameters
		.SIMULATION         (SIMULATION)
) memif0 (
		.clk                 (memif_clk),
		.rst                 (memif_rst),
		.clk_ref             (memif_clk_ref),
		.mem_refclk          (memif_mem_refclk),
		.freq_refclk         (memif_freq_refclk),
		.sync_pulse          (memif_sync_pulse),
		.rst_phaser_ref      (memif_rst_phaser_ref),
		.pll_locked          (pll_lock),
		.ref_dll_lock        (memif_ref_dll_lock),
		.calib_done          (memif_calib_done),
		
		.app_rdy             (memif_app_rdy),
		.app_en              (memif_app_en),
		.app_cmd             (memif_app_cmd),
		.app_addr            (memif_app_addr),
	
		.app_rd_data         (memif_app_rd_data),
		.app_rd_data_end     (memif_app_rd_data_end), 
		.app_rd_data_valid   (memif_app_rd_data_valid),
	
		.app_wdf_rdy         (memif_app_wdf_rdy),
		.app_wdf_wren        (memarb_app_wdf_wren),
		.app_wdf_data        (memif_app_wdf_data),
		.app_wdf_end         (memarb_app_wdf_end),
		.app_wdf_mask        (memarb_app_wdf_mask),
		
		.ddr3_dq             (ddr3_dq),
		.ddr3_addr           (ddr3_addr),
		.ddr3_ba             (ddr3_ba),
		.ddr3_ck_p           (ddr3_ck_p),
		.ddr3_ck_n           (ddr3_ck_n),
		.ddr3_cke            (ddr3_cke),
		.ddr3_cs_n           (ddr3_cs_n),
		.ddr3_cas_n          (ddr3_cas_n),
		.ddr3_ras_n          (ddr3_ras_n),
		.ddr3_we_n           (ddr3_we_n),
		.ddr3_odt            (ddr3_odt),
		.ddr3_dm             (ddr3_dm),
		.ddr3_dqs_p          (ddr3_dqs_p),
		.ddr3_dqs_n          (ddr3_dqs_n),
		.ddr3_reset_n        (ddr3_reset_n)
	
	);


// Phase shift is performed in order to accommodate the setup/hold
// requirements of the Spartan-6:
// + We capture PIX_DATA, FV, and LV on the falling edge of PIX_CLK.
// + FV/LV may arrive as late as 1.0ns before the falling edge.
// + The setup time for Spartan-6 is approximately 1.8ns.
// + No phase shift is required when the DCM runs in SOURCE_SYNCHRONOUS
//   mode, but some positive shift may be added to improve margin.
clocks # (
		// MIG Parameters
		.TCQ                (100),
		.nCK_PER_CLK        (4),         // 
		.CLKIN_PERIOD       (5000),     // System clock is 100 MHz
		.SYSCLK_TYPE        ("DIFFERENTIAL"),
		.CLKFBOUT_MULT      (4),         //PLL VCO multiplier -> 800MHz
		.DIVCLK_DIVIDE      (1),         //PLL VCO divisor -> 800Mhz
		.CLKOUT0_PHASE      (337.5),     //Phase for PLL output clock (CLKOUT0)
		.CLKOUT0_DIVIDE     (2),         // VCO output divisor  -> 400MHz = freq_refclock
		.CLKOUT1_DIVIDE     (2),         // VCO output divisor  -> 400MHz = mem_refclock
		.CLKOUT2_DIVIDE     (32),        // VCO output divisor  -> 25MHz = sync_pulse
		.CLKOUT3_DIVIDE     (8),         // VCO output divisor  -> 100MHz MMCM Input Clock = clk
		.RST_ACT_LOW        (0),         // 0 For active high
		// EVB Parameters
		.CLKOUT4_DIVIDE     (40),        // VCO output divisor  -> 20MHz Pix Ext Clk = pix_extclk_o
		.C_CLKPIXEXT_DIVIDE (31),        // Image sensor EXTCLK output is 20 MHz
		.PIXGEN_PHASE_SHIFT (0)          // Phase shift for PIX_CLK generation
	) clkinst0 (
		.sys_clk            (1'b0),
		.sys_clk_p          (sys_clkp),
		.sys_clk_n          (sys_clkn),
		.sys_rst            (reset_syspll),
		//MIG Clocks
		.clk                (memif_clk),              // Fabric clock freq at quarter rate.
		.clk_ref            (memif_clk_ref),          // IODELAY Reference Clock
		.mem_refclk         (memif_mem_refclk),       // Equal to  memory clock
		.freq_refclk        (memif_freq_refclk),      // Reference Clock
		.pll_locked         (pll_lock),               // Locked output from PLLE2_ADV
		.sync_pulse         (memif_sync_pulse),       // Exactly 1/16 of mem_refclk 
		.rstdiv0            (memif_rst),              // Reset CLK and CLKDIV logic (incl I/O),
		.rst_phaser_ref     (memif_rst_phaser_ref),
		.ref_dll_lock       (memif_ref_dll_lock),
		//Sensor Clocks
		.pix_extclk     (pix_extclk_o),
		.pix_clk        (pix_clk),
		.reset_pixdcm   (reset_pixdcm),
		.clk_pix        (clk_pix)
	);
	
//Block Throttle
always @(posedge okClk) begin
		
		if(pipe_out_rd_count >= BLOCK_SIZE) begin
		  pipe_out_ready <= 1'b1;
		end
		else begin
			pipe_out_ready <= 1'b0;
		end
		
end



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
okWireIn     wi01  (.okHE(okHE),                             .ep_addr(8'h01), .ep_dataout(memdin));
okWireIn     wi02  (.okHE(okHE),                             .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireIn     wi03  (.okHE(okHE),                             .ep_addr(8'h03), .ep_dataout(ep03wire));
okWireIn     wi04  (.okHE(okHE),                             .ep_addr(8'h04), .ep_dataout(ep04wire));
okWireIn     wi05  (.okHE(okHE),                             .ep_addr(8'h05), .ep_dataout(ep05wire));

okTriggerIn  ti40a (.okHE(okHE),                             .ep_addr(8'h40), .ep_clk(clk_pix),  .ep_trigger(ti40_pix));
okTriggerIn  ti40b (.okHE(okHE),                             .ep_addr(8'h40), .ep_clk(memif_clk),     .ep_trigger(ti40_mig));
okTriggerIn  ti42  (.okHE(okHE),                             .ep_addr(8'h42), .ep_clk(clk_ti),   .ep_trigger(ti42_clkti));

okTriggerOut to60  (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'h60), .ep_clk(clk_pix),  .ep_trigger(to60_pix));
okTriggerOut to61  (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]), .ep_addr(8'h61), .ep_clk(clk_ti),   .ep_trigger(to61_clkti));

okPipeOut    po0   (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]), .ep_addr(8'ha0), .ep_read(pipe_out_ep_read),   .ep_datain(pipe_out_datain));
//okBTPipeOut    po0   (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]), .ep_addr(8'ha0), .ep_read(pipe_out_ep_read),   .ep_datain(pipe_out_datain),  .ep_ready(pipe_out_ready));

okWireOut    wo20  (.okHE(okHE), .okEH(okEHx[ 3*65 +: 65 ]), .ep_addr(8'h20), .ep_datain({21'b0, pipe_out_rd_count}));
okWireOut    wo21  (.okHE(okHE), .okEH(okEHx[ 4*65 +: 65 ]), .ep_addr(8'h21), .ep_datain(32'b0));
okWireOut    wo22  (.okHE(okHE), .okEH(okEHx[ 5*65 +: 65 ]), .ep_addr(8'h22), .ep_datain({24'b0, memdout}));
okWireOut    wo23  (.okHE(okHE), .okEH(okEHx[ 6*65 +: 65 ]), .ep_addr(8'h23), .ep_datain({23'b0, ~buff_addr_fifo_empty_comb, missed_count[7:0]}));
okWireOut    wo24  (.okHE(okHE), .okEH(okEHx[ 7*65 +: 65 ]), .ep_addr(8'h24), .ep_datain(buff_addr_fifo_count));
okWireOut    wo3e  (.okHE(okHE), .okEH(okEHx[ 8*65 +: 65 ]), .ep_addr(8'h3e), .ep_datain({16'b0, CAPABILITY}));
okWireOut    wo3f  (.okHE(okHE), .okEH(okEHx[ 9*65 +: 65 ]), .ep_addr(8'h3f), .ep_datain({16'b0, VERSION}));

endmodule
 

module i2cController (clk, reset, start, done, divclk, memclk, memstart, memwrite, memread, memdin, memdout, i2c_sclk, i2c_sdat_in, i2c_sdat_out, i2c_drive);
	input  wire      clk;
	input  wire      reset;
	input  wire      start;
	output       done;
	input  [7:0] divclk;
	
	input  wire      memclk;
	input  wire      memstart;
	input  wire      memwrite;
	input  wire      memread;
	input  wire [7:0] memdin;
	output [7:0] memdout;
	
	output       i2c_sclk;
	input  wire      i2c_sdat_in;
	output       i2c_sdat_out;
	output       i2c_drive;
// synthesis attribute box_type i2cController "black_box"
endmodule



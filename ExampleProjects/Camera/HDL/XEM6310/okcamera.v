//------------------------------------------------------------------------
// xem6010.v - Top-level EVB1005 camera HDL
//
// Clocks:
//    SYS_CLKP/N - 100 MHz differential input clock
//    CLK_TI     - 100 MHz host-interface clock provided by okHost
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
//     0 - Readout start
//     1 - Readout done
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
// $Rev$ $Date$
//------------------------------------------------------------------------
`timescale 1ns/1ps
// Don't use this because the Xilinx MIG generates code that doesn't declare
// net types on module inputs, so it's not compliant.
//`default_nettype none

module evb1005 (
	input  wire [4:0]  okUH,
	output wire [2:0]  okHU,
	inout  wire [31:0] okUHU,
	inout  wire        okAA,
	
	output wire [7:0]  led,
	
	//Clocks
	input  wire        sys_clkp,  // 100 MHz
	input  wire        sys_clkn,  // 100 MHz
	
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
	inout  wire [15:0] ddr2_dq,
	output wire [12:0] ddr2_a,
	output wire [2:0]  ddr2_ba,
	output wire        ddr2_ras_n,
	output wire        ddr2_cas_n,
	output wire        ddr2_we_n,
	output wire        ddr2_odt,
	output wire        ddr2_cke,
	output wire        ddr2_dm,
	inout  wire        ddr2_udqs,
	inout  wire        ddr2_udqs_n,
	inout  wire        ddr2_rzq,
	inout  wire        ddr2_zio,
	output wire        ddr2_udm,
	inout  wire        ddr2_dqs,
	inout  wire        ddr2_dqs_n,
	output wire        ddr2_ck,
	output wire        ddr2_ck_n,
	output wire        ddr2_cs_n
	);

localparam BLOCK_SIZE                = 128/4;
localparam TOTAL_MEM                 = 134217728;
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

// MIG harnessing
wire         clk0;
wire         calib_done;
reg  [1:0]   calib_done_memclk;
wire         memif_async_rst;
wire         memif_sysclk_2x;
wire         memif_sysclk_2x_180;
wire         memif_pll_ce_0;
wire         memif_pll_ce_90;
wire         pll_lock;
wire         memif_mcb_drp_clk;
wire         p0_cmd_en;
wire [2:0]   p0_cmd_instr;
wire [5:0]   p0_cmd_bl;
wire [29:0]  p0_cmd_byte_addr;
wire         p0_wr_en;
wire [63:0]  p0_wr_data;
wire [7:0]   p0_wr_mask;
wire         p1_cmd_en;
wire [2:0]   p1_cmd_instr;
wire [5:0]   p1_cmd_bl;
wire [29:0]  p1_cmd_byte_addr;
wire         p1_rd_clk;
wire         p1_rd_en;
wire [63:0]  p1_rd_data;
wire         p1_rd_empty;

//OK
wire [31:0] ep00wire, ep02wire, ep03wire, ep04wire, ep05wire;
wire [31:0] ti40_pix, ti40_mig, ti42_clkti;
wire [31:0] to60_pix, to61_clkti;
wire        pipe_out_ep_read;
wire [31:0] pipe_out_datain;
wire [10:0] pipe_out_rd_count;
wire        imgctl_packing_mode;
wire        frame_done_t;
wire        clk_pix;
wire        i2c_sdat_out;
wire        i2c_drive;
wire        pix_extclk_o;


assign pix_trigger    = 1'b0;
assign pix_sdata = (i2c_drive) ? (i2c_sdat_out) : (1'bz);
ODDR2 i_pixext (.Q   (pix_extclk),
                .C0  (pix_extclk_o),
                .C1  (~pix_extclk_o),
                .D0  (1'b1),
                .D1  (1'b0),
                .CE  (pll_lock),
                .R   (~pll_lock),
                .S   (1'b0));


// Reset Chain
wire reset_syspll;
wire reset_pixdcm;
wire reset_async;
wire reset_clkpix;
wire reset_clkti;
wire reset_clk0;

assign reset_syspll        =  ep00wire[0];
assign pix_reset           = ~ep00wire[1];
assign reset_pixdcm        =  ep00wire[2];
assign reset_async         =  ep00wire[3];
assign imgctl_packing_mode =  ep00wire[5];


// Create RESETs that deassert synchronous to specific clocks
sync_reset sync_reset0 (.clk(clk_pix),  .async_reset(reset_async),  .sync_reset(reset_clkpix));
sync_reset sync_reset1 (.clk(clk0),     .async_reset(reset_async),  .sync_reset(reset_clk0));
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
wire [29:0]  input_buffer_addr_pixclk;
wire [29:0]  input_buffer_addr_memclk;
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
	.clk                        (clk0),
	.rst                        (reset_clk0),
	.missed_count               (missed_count),
	.imgif_trig                 (imgif_trig_memclk),
	.imgctl_framedone           (imgctl_framedone_memclk),
	.imgctl_framewritten        (imgctl_framedone_memclk),
	.input_buffer_addr          (input_buffer_addr_memclk),
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
	.memif_calib_done           (calib_done_memclk[1])
);

sync_trig sync_imgctl_framedone(
	.clk_i (clk_pix),
	.clk_o (clk0),
	.rst_i (reset_clkpix),
	.rst_o (reset_clk0),
	.trig_i (imgctl_framedone_pixclk),
	.trig_o (imgctl_framedone_memclk)
);

sync_trig sync_imgif_trig(
	.clk_i (clk0),
	.clk_o (clk_pix),
	.rst_i (reset_clk0),
	.rst_o (reset_clkpix),
	.trig_i (imgif_trig_memclk),
	.trig_o (imgif_trig_pixclk)
);

assign led = ~{ using_prog_full, output_buffer_behind, buff_addr_fifo_full_comb, buff_addr_fifo_empty_comb, calib_done, pll_lock, reset_async, 1'b1 };

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
	.clk_dst (clk0),
	.reset   (reset_clkti),
	.bus_src (img_size),
	.bus_dst (img_size_memclk)
);

sync_bus # (
	.N (30)
) sync_input_buffer_addr (
	.clk_src (clk0),
	.clk_dst (clk_pix),
	.reset   (reset_clk0),
	.bus_src (input_buffer_addr_memclk),
	.bus_dst (input_buffer_addr_pixclk)
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

// Synchronize calib_done to the memory clock domain
always@ (posedge clk0) begin
	if (reset_clk0) begin
		calib_done_memclk <= 2'b00;
	end else begin
		calib_done_memclk[0] <= calib_done;
		calib_done_memclk[1] <= calib_done_memclk[0];
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
		.start_addr          (input_buffer_addr_pixclk),
		.frame_done          (imgctl_framedone_pixclk),
		.skipped             (imgctl_skipped),
		
		.mem_wr_en           (p0_wr_en),
		.mem_wr_data         (p0_wr_data),
		.mem_wr_mask         (p0_wr_mask),
		.mem_cmd_en          (p0_cmd_en),
		.mem_cmd_instr       (p0_cmd_instr),
		.mem_cmd_byte_addr   (p0_cmd_byte_addr),
		.mem_cmd_burst_len   (p0_cmd_bl)
	);



host_if hstif0(
		.clk                (clk0),
		.clk_ti             (clk_ti),
		.reset_clk          (reset_clk0),
		.readout_start      (output_buffer_start),
		.readout_done       (output_buffer_done),
		.readout_addr       (output_buffer_addr),
		.readout_count      ({ep03wire[7:0], ep02wire[15:0]}),
		.mem_rd_en          (p1_rd_en),
		.mem_rd_data        (p1_rd_data),
		.mem_rd_empty       (p1_rd_empty),
		.mem_cmd_en         (p1_cmd_en),
		.mem_cmd_instr      (p1_cmd_instr),
		.mem_cmd_byte_addr  (p1_cmd_byte_addr),
		.mem_cmd_burst_len  (p1_cmd_bl), 
	
		.ob_rd_en           (pipe_out_ep_read),
		.pofifo0_rd_count   (pipe_out_rd_count),  
		.pofifo0_dout       (pipe_out_datain),
		.pofifo0_full       (),
		.pofifo0_empty      ()
	);



wire [15:0] memdin;
wire [7:0]  memdout;
i2cController i2c_ctrl0 (
		.clk          (clk_ti),
		.reset        (reset_clkti),
		.start        (ti42_clkti[0]),
		.done         (to61_clkti[0]),
		.divclk       (8'd47),
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



mem_if memif0 (
		.async_rst           (memif_async_rst),
		.sysclk_2x           (memif_sysclk_2x),
		.sysclk_2x_180       (memif_sysclk_2x_180),
		.pll_ce_0            (memif_pll_ce_0),
		.pll_ce_90           (memif_pll_ce_90),
		.mcb_drp_clk         (memif_mcb_drp_clk),
		.pll_lock            (pll_lock),
		.calib_done          (calib_done),
		.p0_cmd_clk          (clk_pix),
		.p0_cmd_en           (p0_cmd_en),
		.p0_cmd_instr        (p0_cmd_instr),
		.p0_cmd_bl           (p0_cmd_bl),
		.p0_cmd_byte_addr    (p0_cmd_byte_addr),
		.p0_wr_clk           (clk_pix),
		.p0_wr_en            (p0_wr_en),
		.p0_wr_data          (p0_wr_data),
		.p0_wr_mask          (p0_wr_mask),
		.p1_cmd_clk          (clk0),
		.p1_cmd_en           (p1_cmd_en),
		.p1_cmd_instr        (p1_cmd_instr),
		.p1_cmd_bl           (p1_cmd_bl),
		.p1_cmd_byte_addr    (p1_cmd_byte_addr),
		.p1_rd_clk           (clk0),
		.p1_rd_en            (p1_rd_en),
		.p1_rd_data          (p1_rd_data),
		.p1_rd_empty         (p1_rd_empty),
		.ddr2_ck             (ddr2_ck),
		.ddr2_ck_n           (ddr2_ck_n),
		.ddr2_cke            (ddr2_cke),
		.ddr2_cs_n           (ddr2_cs_n),
		.ddr2_we_n           (ddr2_we_n),
		.ddr2_ras_n          (ddr2_ras_n),
		.ddr2_cas_n          (ddr2_cas_n),
		.ddr2_odt            (ddr2_odt),
		.ddr2_a              (ddr2_a),
		.ddr2_ba             (ddr2_ba),
		.ddr2_dq             (ddr2_dq),
		.ddr2_dm             (ddr2_dm),
		.ddr2_dqs            (ddr2_dqs),
		.ddr2_dqs_n          (ddr2_dqs_n),
		.ddr2_udm            (ddr2_udm),
		.ddr2_udqs           (ddr2_udqs),
		.ddr2_udqs_n         (ddr2_udqs_n),
		.ddr2_rzq            (ddr2_rzq),
		.ddr2_zio            (ddr2_zio)
	);



// Phase shift is performed in order to accommodate the setup/hold
// requirements of the Spartan-6:
// + We capture PIX_DATA, FV, and LV on the falling edge of PIX_CLK.
// + FV/LV may arrive as late as 1.0ns before the falling edge.
// + The setup time for Spartan-6 is approximately 1.8ns.
// + No phase shift is required when the DCM runs in SOURCE_SYNCHRONOUS
//   mode, but some positive shift may be added to improve margin.
clocks # (
		.C_RST_ACT_LOW           (0),
		.C_INPUT_CLK_TYPE        ("DIFFERENTIAL"),
		.C_INCLK_PERIOD          (10000),     // System clock is 100 MHz
		.C_DIVCLK_DIVIDE         (5),         // Divide to 20 MHz
		.C_CLKFBOUT_MULT         (31),        // VCO frequency is 620 MHz
		.C_CLKDDR0_DIVIDE        (1),         // DDR @ 620 MHz (0-phase)
		.C_CLKDDR1_DIVIDE        (1),         // DDR @ 620 MHz (180-phase)
		.C_CLKSYS_DIVIDE         (5),         // Logic clock is 124 MHz
		.C_CLKMCB_DIVIDE         (8),         // MCB @ 77.5 MHz
		.C_CLKPIXEXT_DIVIDE      (31),        // Image sensor EXTCLK output is 20 MHz
		.PIXGEN_PHASE_SHIFT      (0)          // Phase shift for PIX_CLK generation
	) clkinst0 (
		.sys_clk        (1'b0),
		.sys_clk_p      (sys_clkp),
		.sys_clk_n      (sys_clkn),
		.sys_rst_n      (reset_syspll),
		.clk0           (clk0),
		.rst0           (),
		.async_rst      (memif_async_rst),
		.sysclk_2x      (memif_sysclk_2x),
		.sysclk_2x_180  (memif_sysclk_2x_180),
		.pll_ce_0       (memif_pll_ce_0),
		.pll_ce_90      (memif_pll_ce_90),
		.pll_lock       (pll_lock),
		.mcb_drp_clk    (memif_mcb_drp_clk),

		.pix_extclk     (pix_extclk_o),
		.pix_clk        (pix_clk),
		.reset_pixdcm   (reset_pixdcm),
		.clk_pix        (clk_pix)
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
okWireIn     wi01  (.okHE(okHE),                             .ep_addr(8'h01), .ep_dataout(memdin));
okWireIn     wi02  (.okHE(okHE),                             .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireIn     wi03  (.okHE(okHE),                             .ep_addr(8'h03), .ep_dataout(ep03wire));
okWireIn     wi04  (.okHE(okHE),                             .ep_addr(8'h04), .ep_dataout(ep04wire));
okWireIn     wi05  (.okHE(okHE),                             .ep_addr(8'h05), .ep_dataout(ep05wire));

okTriggerIn  ti40a (.okHE(okHE),                             .ep_addr(8'h40), .ep_clk(clk_pix),  .ep_trigger(ti40_pix));
okTriggerIn  ti40b (.okHE(okHE),                             .ep_addr(8'h40), .ep_clk(clk0),     .ep_trigger(ti40_mig));
okTriggerIn  ti42  (.okHE(okHE),                             .ep_addr(8'h42), .ep_clk(clk_ti),   .ep_trigger(ti42_clkti));

okTriggerOut to60  (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'h60), .ep_clk(clk_pix),  .ep_trigger(to60_pix));
okTriggerOut to61  (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]), .ep_addr(8'h61), .ep_clk(clk_ti),   .ep_trigger(to61_clkti));

okPipeOut    po0   (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]), .ep_addr(8'ha0), .ep_read(pipe_out_ep_read),   .ep_datain(pipe_out_datain));

okWireOut    wo20  (.okHE(okHE), .okEH(okEHx[ 3*65 +: 65 ]), .ep_addr(8'h20), .ep_datain({21'b0, pipe_out_rd_count}));
okWireOut    wo21  (.okHE(okHE), .okEH(okEHx[ 4*65 +: 65 ]), .ep_addr(8'h21), .ep_datain(32'b0));
okWireOut    wo22  (.okHE(okHE), .okEH(okEHx[ 5*65 +: 65 ]), .ep_addr(8'h22), .ep_datain({24'b0, memdout}));
okWireOut    wo23  (.okHE(okHE), .okEH(okEHx[ 6*65 +: 65 ]), .ep_addr(8'h23), .ep_datain({23'b0, ~buff_addr_fifo_empty_comb, missed_count[7:0]}));
okWireOut    wo24  (.okHE(okHE), .okEH(okEHx[ 7*65 +: 65 ]), .ep_addr(8'h24), .ep_datain(buff_addr_fifo_count));
okWireOut    wo3e  (.okHE(okHE), .okEH(okEHx[ 8*65 +: 65 ]), .ep_addr(8'h3e), .ep_datain({16'b0, CAPABILITY}));
okWireOut    wo3f  (.okHE(okHE), .okEH(okEHx[ 9*65 +: 65 ]), .ep_addr(8'h3f), .ep_datain({16'b0, VERSION}));

endmodule
 

module i2cController (clk, reset, start, done, divclk, memclk, memstart, memwrite, memread, memdin, memdout, i2c_sclk, i2c_sdat_in, i2c_sdat_out, i2c_drive);
	input        clk;
	input        reset;
	input        start;
	output       done;
	input  [7:0] divclk;
	
	input        memclk;
	input        memstart;
	input        memwrite;
	input        memread;
	input  [7:0] memdin;
	output [7:0] memdout;
	
	output       i2c_sclk;
	input        i2c_sdat_in;
	output       i2c_sdat_out;
	output       i2c_drive;
// synthesis attribute box_type i2cController "black_box"
endmodule



//------------------------------------------------------------------------
// okcamera.v - Top-level EVB1007 camera HDL
//
// Clocks:
//    SYS_CLK    - 50 MHz single ended input clock
//    CLK_TI     - 100 MHz host-interface clock provided by okHost
//    PHY_CLK    - Memory interface clock provided by ALTERA HPC
//    CLK_PIX    - 96 MHz single-ended input clock from image sensor
//
//
// Host Interface registers:
// WireIn 0x00
//     0 - System PLL RESET (active high)
//     1 - Image sensor RESET (active high)
//     2 - Pixel DCM RESET (active high)
//     3 - Logic RESET (active high)
//     4 - Image capture mode (0=trigger, 1=ping-pong)
//     5 - Image packing mode (0=8-bit, 1=16-bit)
// WireIn 0x01
//   7:0 - I2C input data
// WireIn 03:02 - readout_count[23:0]
// WireIn 05:04 - readout_addr[29:0]
//
// WireOut 0x20
//  10:0 - Image buffer read count
// WireOut 0x21
//     0 - Reset complete
// WireOut 0x22
//  15:0 - I2C data output
// WireOut 0x23
//   7:0 - Skipped frame count
//
// TriggerIn 0x40
//     0 - Image capture
//     1 - Readout start
//     2 - Readout complete (buffer A)
//     3 - Readout complete (buffer B)
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
// net types on module inputs, so it's not compliant.
//`default_nettype none

module evb1007 (
	input  wire [4:0]  okUH,
	output wire [2:0]  okHU,
	inout  wire [31:0] okUHU,
	inout  wire        okAA,
	
	output wire [1:0]  led,
	
	//Clocks
	input  wire        sys_clk,  // 50 MHz
	
	//EVB1007
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
	
	//Focus
	//output wire        focus_scl,
	//output wire        focus_sda,
	//output wire        focus_sdi,
	//output wire        focus_sdo,
	//output wire        focus_sck,
	//output wire        focus_ss,
	//output wire        focus_rst_n,
	
	//DDR Memory
	inout  wire [15:0] mem_dq,
	output wire [12:0] mem_addr,
	output wire [2:0]  mem_ba,
	output wire        mem_ras_n,
	output wire        mem_cas_n,
	output wire        mem_we_n,
	output wire  [0:0] mem_odt,
	output wire  [0:0] mem_cke,
	output wire  [1:0] mem_dm,
	inout  wire  [1:0] mem_dqs,
	inout wire  [0:0] mem_clk,
	inout wire  [0:0] mem_clk_n,
	output wire  [0:0] mem_cs_n
	);

localparam BLOCK_SIZE      = 128/4;

// HDL Version
// Top 8 bits signify the major version
// Bottom 8 bits used to indicate a minor version
localparam VERSION    = 16'h01_00;
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
wire         memif_init_done;
wire         memif_pll_locked;

wire         memif_phy_clk; // 66.5MHz
wire         memif_reset_phy_clk_n;

wire         memif_ready;
wire         memif_burstbegin;
wire [23:0]  memif_address;
wire [3:0]   memif_size;

wire [7:0]   memif_be;
wire         memif_write_req;
wire [63:0]  memif_wdata;

wire         memif_read_req;
wire         memif_rdata_valid;
wire [63:0]  memif_rdata;

// MIG Read/Write Arbiter
wire                                memarb_wr_req;
wire  [23:0]                        memarb_wr_addr;
wire                                memarb_wr_ack;
wire                                memarb_rd_req;
wire  [23:0]                        memarb_rd_addr;
wire                                memarb_rd_ack;
wire                                memarb_wdata_rd_en;

wire                                imgif0_fifo_full;
wire                                imgif0_fifo_empty;
wire                                hstif0_fifo_full;
wire                                hstif0_fifo_empty;


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


wire        extclk_pll_lock;
wire        pixclk_pll_lock;

assign pix_trigger    = 1'b0;
assign led = ~{hstif0_fifo_empty, imgif0_fifo_empty};
assign pix_sdata = (i2c_drive) ? (i2c_sdat_out) : (1'bz);

// Reset Chain
wire reset_syspll;
wire reset_pixpll;
wire reset_async;
wire reset_clkpix;
wire reset_clkti;
wire reset_phyclk;

assign reset_syspll        =  ep00wire[0];
assign pix_reset           = ~ep00wire[1];
assign reset_pixpll        =  ep00wire[2];
assign reset_async         =  ep00wire[3];
assign imgctl_packing_mode =  ep00wire[5];


// Create RESETs that deassert synchronous to specific clocks
sync_reset sync_reset0 (.clk(clk_pix),  .async_reset(reset_async),  .sync_reset(reset_clkpix));
sync_reset sync_reset1 (.clk(memif_phy_clk),     .async_reset(reset_async),  .sync_reset(reset_phyclk));
sync_reset sync_reset2 (.clk(clk_ti),   .async_reset(reset_async),  .sync_reset(reset_clkti));


// Coordinator
// * Manual mode - Start image capture from host.
// * Ping-Pong mode - Automatic double-buffered continual capture
wire         pingpong = ep00wire[4];
wire         imgctl_framedone;
wire         imgctl_skipped;
reg  [7:0]   skipped_count;
wire [7:0]   skipped_count_clkti;
reg  [1:0]   buffer_done;
reg  [1:0]   buffer_full;
wire [1:0]   buffer_full_clkti;
reg          ping_trig;
reg  [29:0]  ping_addr;
integer stateA;
localparam a_idle             = 0,
           a_bufA_wait        = 1,
           a_bufA_capture     = 2,
           a_bufB_wait        = 3,
           a_bufB_capture     = 4;
always @(posedge clk_pix or posedge reset_clkpix) begin
	if (reset_clkpix) begin
		stateA        <= a_idle;
		buffer_full   <= 2'b00;
		buffer_done   <= 2'b00;
		ping_trig     <= 1'b0;
		skipped_count <= 8'h00;
	end else begin
		ping_trig <= 1'b0;
		buffer_done <= 2'b00;
		
		if (imgctl_skipped) begin
			skipped_count <= skipped_count + 1'b1;
		end
		
		if (ti40_pix[2] == 1'b1)
			buffer_full[0] <= 1'b0;
		if (ti40_pix[3] == 1'b1)
			buffer_full[1] <= 1'b0;
		
		case (stateA)
			a_idle: begin
				stateA <= a_bufA_wait;
			end
			
			a_bufA_wait: begin
				if (buffer_full[0] == 1'b0) begin
					stateA <= a_bufA_capture;
					ping_trig <= 1'b1;
					ping_addr <= 30'h00000000;
				end
			end
			
			a_bufA_capture: begin
				if (imgctl_framedone == 1'b1) begin
					stateA <= a_bufB_wait;
					buffer_full[0] <= 1'b1;
					buffer_done[0] <= 1'b1;
				end
			end

			a_bufB_wait: begin
				if (buffer_full[1] == 1'b0) begin
					stateA <= a_bufB_capture;
					ping_trig <= 1'b1;
					ping_addr <= 30'h00800000;
				end
			end

			a_bufB_capture: begin
				if (imgctl_framedone == 1'b1) begin
					stateA <= a_bufA_wait;
					buffer_full[1] <= 1'b1;
					buffer_done[1] <= 1'b1;
				end
			end
		endcase
	end
end

sync_bus # (
	.N                (2)
) sync_buffer_full (
	.clk_src          (clk_pix),
	.clk_dst          (clk_ti),
	.reset            (reset_clkpix),
	.bus_src          (buffer_full),
	.bus_dst          (buffer_full_clkti)
);

sync_bus # (
	.N                (8)
) sync_skipped_count (
	.clk_src          (clk_pix),
	.clk_dst          (clk_ti),
	.reset            (reset_clkpix),
	.bus_src          (skipped_count),
	.bus_dst          (skipped_count_clkti)
);



// Image Sensor Interface
assign to60_pix[0] = imgctl_framedone;
assign to60_pix[1] = | buffer_done;
assign to60_pix[2] = buffer_done[0];
assign to60_pix[3] = buffer_done[1];
assign to60_pix[31:4] = 0;
assign to61_clkti[31:1] = 0;

image_if imgif0(
		.clk                 (clk_pix),
		.reset               (reset_clkpix),
		.packing_mode        (imgctl_packing_mode),
	
		.pix_fv              (pix_fv),
		.pix_lv              (pix_lv),
		.pix_data            (pix_data),
		
		.trigger             (pingpong ? ping_trig : ti40_pix[0]),
		.start_addr          (pingpong ? ping_addr : 30'h0),
		.frame_done          (imgctl_framedone),
		.skipped             (imgctl_skipped),
		
		.mem_clk             (memif_phy_clk),
		.mem_reset           (reset_phyclk),
		
		.mem_wr_req          (memarb_wr_req),
		.mem_wr_addr         (memarb_wr_addr),
		.mem_wr_ack          (memarb_wr_ack),
		
		.mem_wdata_rd_en     (memarb_wdata_rd_en),
		.mem_wdata           (memif_wdata),
		.fifo_full           (imgif0_fifo_full),
		.fifo_empty          (imgif0_fifo_empty)
	);


host_if hstif0(
		.clk                (memif_phy_clk),
		.clk_ti             (clk_ti),
		.reset_clk          (reset_phyclk),
		.readout_start      (ti40_mig[1]),
		.readout_done       (ti40_mig[2] | ti40_mig[3]),
		.readout_addr       ({ep05wire[13:0], ep04wire[15:0]}),
		.readout_count      ({ep03wire[7:0], ep02wire[15:0]}),
		
		.mem_rd_req         (memarb_rd_req),
		.mem_rd_addr        (memarb_rd_addr),
		.mem_rd_ack         (memarb_rd_ack),
		
		.mem_rdata          (memif_rdata),
		.mem_rdata_valid    (memif_rdata_valid),
	
		.ob_rd_en           (pipe_out_ep_read),
		.pofifo0_rd_count   (pipe_out_rd_count),  
		.pofifo0_dout       (pipe_out_datain),
		.pofifo0_full       (hstif0_fifo_full),
		.pofifo0_empty      (hstif0_fifo_empty)
	);

wire [15:0] memdin;
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
	.clk                   (memif_phy_clk),
	.reset                 (~memif_reset_phy_clk_n),
	.calib_done            (memif_init_done),
	
	.hpc_ready             (memif_ready),
	.hpc_burstbegin        (memif_burstbegin),
	.hpc_size              (memif_size),
	.hpc_address           (memif_address),
	
	.hpc_be                (memif_be),
	.hpc_write_req         (memif_write_req),
	.hpc_read_req          (memif_read_req),
	
	.rdata_valid           (memif_rdata_valid),
	.wdata_rd_en           (memarb_wdata_rd_en),
	
	.wr_req                (memarb_wr_req),
	.wr_ack                (memarb_wr_ack),
	.wr_addr               (memarb_wr_addr),
	.rd_req                (memarb_rd_req),
	.rd_ack                (memarb_rd_ack),
	.rd_addr               (memarb_rd_addr)
	);

mem_if memif0 (
		.async_rst          (reset_async),
		.sys_clk            (sys_clk),
		.phy_clk            (memif_phy_clk),
		.reset_phy_clk_n    (memif_reset_phy_clk_n),
		.local_init_done    (memif_init_done),
		.local_pll_locked   (memif_pll_locked),
		
		.local_ready        (memif_ready),
		.local_burstbegin   (memif_burstbegin),
		.local_address      (memif_address),
		.local_size         (memif_size),
	
		.local_be           (memif_be),
		.local_write_req    (memif_write_req),
		.local_wdata        (memif_wdata),

		.local_read_req     (memif_read_req),
		.local_rdata_valid  (memif_rdata_valid),
		.local_rdata        (memif_rdata),
		
		.mem_clk            (mem_clk),
		.mem_clk_n          (mem_clk_n),
		.mem_cke            (mem_cke),
		.mem_cs_n           (mem_cs_n),
		.mem_we_n           (mem_we_n),
		.mem_ras_n          (mem_ras_n),
		.mem_cas_n          (mem_cas_n),
		.mem_odt            (mem_odt),
		.mem_addr           (mem_addr),
		.mem_ba             (mem_ba),
		.mem_dq             (mem_dq),
		.mem_dm             (mem_dm),
		.mem_dqs            (mem_dqs)
	);


// Phase shift is performed in order to accommodate the setup/hold
// requirements of the Cyclone IV:
// + We capture PIX_DATA, FV, and LV on the falling edge of PIX_CLK.
// + FV/LV may arrive as late as 1.0ns before the falling edge.
// + The setup time for Cyclone IV is approximately ???ns.
// + No phase shift is required when the DCM runs in SOURCE_SYNCHRONOUS
//   mode, but some positive shift may be added to improve margin.
clocks clkinst0 (
		.clk            (memif_phy_clk),
		.reset          (~memif_pll_locked | reset_syspll),
		.ext_pll_lock   (extclk_pll_lock),
		.pix_extclk     (pix_extclk),
		
		.pix_clk        (pix_clk),
		.reset_pixpll   (reset_pixpll),
		.pix_pll_lock   (pixclk_pll_lock),
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
wire [65*9-1:0]  okEHx;
okHost okHI(
	.okUH(okUH),
	.okHU(okHU),
	.okUHU(okUHU),
	.okAA(okAA),
	.okClk(okClk),
	.okHE(okHE), 
	.okEH(okEH)
);

okWireOR # (.N(9)) wireOR (okEH, okEHx);

okWireIn     wi00  (.okHE(okHE),                             .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn     wi01  (.okHE(okHE),                             .ep_addr(8'h01), .ep_dataout(memdin));
okWireIn     wi02  (.okHE(okHE),                             .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireIn     wi03  (.okHE(okHE),                             .ep_addr(8'h03), .ep_dataout(ep03wire));
okWireIn     wi04  (.okHE(okHE),                             .ep_addr(8'h04), .ep_dataout(ep04wire));
okWireIn     wi05  (.okHE(okHE),                             .ep_addr(8'h05), .ep_dataout(ep05wire));

okTriggerIn  ti40a (.okHE(okHE),                             .ep_addr(8'h40), .ep_clk(clk_pix),  .ep_trigger(ti40_pix));
okTriggerIn  ti40b (.okHE(okHE),                             .ep_addr(8'h40), .ep_clk(memif_phy_clk),     .ep_trigger(ti40_mig));
okTriggerIn  ti42  (.okHE(okHE),                             .ep_addr(8'h42), .ep_clk(clk_ti),   .ep_trigger(ti42_clkti));

okTriggerOut to60  (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'h60), .ep_clk(clk_pix),  .ep_trigger(to60_pix));
okTriggerOut to61  (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]), .ep_addr(8'h61), .ep_clk(clk_ti),   .ep_trigger(to61_clkti));

//okPipeOut    po0   (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]), .ep_addr(8'ha0), .ep_read(pipe_out_ep_read),   .ep_datain(pipe_out_datain));
okBTPipeOut    po0   (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]), .ep_addr(8'ha0), .ep_read(pipe_out_ep_read),   .ep_datain(pipe_out_datain),  .ep_ready(pipe_out_ready));

okWireOut    wo20  (.okHE(okHE), .okEH(okEHx[ 3*65 +: 65 ]), .ep_addr(8'h20), .ep_datain({21'b0, pipe_out_rd_count}));
okWireOut    wo21  (.okHE(okHE), .okEH(okEHx[ 4*65 +: 65 ]), .ep_addr(8'h21), .ep_datain(32'b0));
okWireOut    wo22  (.okHE(okHE), .okEH(okEHx[ 5*65 +: 65 ]), .ep_addr(8'h22), .ep_datain({24'b0, memdout}));
okWireOut    wo23  (.okHE(okHE), .okEH(okEHx[ 6*65 +: 65 ]), .ep_addr(8'h23), .ep_datain({22'b0, buffer_full[1:0], skipped_count[7:0]}));
okWireOut    wo3e  (.okHE(okHE), .okEH(okEHx[ 7*65 +: 65 ]), .ep_addr(8'h3e), .ep_datain(CAPABILITY));
okWireOut    wo3f  (.okHE(okHE), .okEH(okEHx[ 8*65 +: 65 ]), .ep_addr(8'h3f), .ep_datain(VERSION));

endmodule

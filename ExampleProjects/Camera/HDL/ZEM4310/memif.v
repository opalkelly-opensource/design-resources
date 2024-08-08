//------------------------------------------------------------------------
// memif.v
//
// Memory interface for the zem4310.
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2009 Opal Kelly Incorporated
// $Rev: 1141 $ $Date: 2012-04-29 18:20:36 -0500 (Sun, 29 Apr 2012) $
//------------------------------------------------------------------------
`timescale 1ns/1ps

module mem_if (

	// Clocks
	input  wire          async_rst,
	input  wire          sys_clk,
	output wire          phy_clk,
	output wire          reset_phy_clk_n,
	output wire          local_init_done,
	output wire          local_pll_locked,

	// Interfaces
	output wire          local_ready,
	input  wire          local_burstbegin,
	input  wire [23:0]   local_address,
	input  wire [3:0]    local_size,
	
	input  wire [7:0]    local_be,
	input  wire          local_write_req,
	input  wire [63:0]   local_wdata,

	input  wire          local_read_req,
	output wire          local_rdata_valid,
	output wire [63:0]   local_rdata,
	
	output wire [ 12: 0] mem_addr,
	output wire [  2: 0] mem_ba,
	output wire          mem_cas_n,
	output wire [  0: 0] mem_cke,
	inout  wire [  0: 0] mem_clk,
	inout  wire [  0: 0] mem_clk_n,
	output wire [  0: 0] mem_cs_n,
	output wire [  1: 0] mem_dm,
	inout  wire [ 15: 0] mem_dq,
	inout  wire [  1: 0] mem_dqs,
	output wire [  0: 0] mem_odt,
	output wire          mem_ras_n,
	output wire          mem_we_n
);

ddr2_interface ddr2_interface_inst (
	.aux_full_rate_clk        (),
	.aux_half_rate_clk        (),
	.global_reset_n           (~async_rst),
	
	.local_init_done          (local_init_done),
	.local_burstbegin         (local_burstbegin),
	
	.local_address            (local_address),
	.local_be                 (local_be),
	.local_rdata              (local_rdata),
	.local_rdata_valid        (local_rdata_valid),
	.local_read_req           (local_read_req),
	.local_ready              (local_ready),
	.local_size               (local_size),
	.local_wdata              (local_wdata),
	.local_write_req          (local_write_req),
	
	.mem_addr                 (mem_addr[12 : 0]),
	.mem_ba                   (mem_ba),
	.mem_cas_n                (mem_cas_n),
	.mem_cke                  (mem_cke),
	.mem_clk                  (mem_clk),
	.mem_clk_n                (mem_clk_n),
	.mem_cs_n                 (mem_cs_n),
	.mem_dm                   (mem_dm[1 : 0]),
	.mem_dq                   (mem_dq),
	.mem_dqs                  (mem_dqs[1 : 0]),
	.mem_odt                  (mem_odt),
	.mem_ras_n                (mem_ras_n),
	.mem_we_n                 (mem_we_n),
	
	.phy_clk                  (phy_clk),
	.pll_ref_clk              (sys_clk),
	.reset_phy_clk_n          (reset_phy_clk_n),
	.reset_request_n          (local_pll_locked),
	.soft_reset_n             (1'b1)
);

endmodule

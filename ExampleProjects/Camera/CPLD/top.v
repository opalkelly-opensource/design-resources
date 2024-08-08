//-------------------------------------------------------------------------
// EVB1005 CPLD HDL
// 
//-------------------------------------------------------------------------
// Copyright (c) 2010 Opal Kelly Incorporated
// $Rev$ $Date$
//-------------------------------------------------------------------------

`timescale 1ns / 1ps
module top(
	input         img_pixclk,
	input         img_fv,
	input         img_lv,
	input         img_strobe,
	input  [11:0] img_pix,
	
	output        fpga_pixclk,
	output        fpga_fv,
	output        fpga_lv,
	output        fpga_strobe,
	output [11:0] fpga_pix
	);


assign fpga_pixclk = img_pixclk;
assign fpga_fv     = img_fv;
assign fpga_lv     = img_lv;
assign fpga_strobe = img_strobe;
assign fpga_pix    = img_pix;

endmodule

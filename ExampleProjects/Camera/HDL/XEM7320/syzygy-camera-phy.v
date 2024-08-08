//------------------------------------------------------------------------
// syzygy-camera-phy.v
//
// Physical interface for HiSPi compatible cameras, including the AR0330
// sensor present on the SYZYGY Camera Pod. This module takes in the 
// serialized LVDS HiSPi interface signals from the camera and converts
// them to a parralel output with 10 bits per pixel. This module also
// performs the synchronization necessary to align the data and inform
// other modules of the start/end of lines/frames.
//
// To use this module, connect the cameras HiSPi interface to the slvs
// inputs and read the data out from this module. Pixel data is output on
// the pix_data wire as 4 10-bit pixels per clock cycle, synchronous to
// the 'clk' output signal. Pixel data is valid when the 'line_valid'
// signal is asserted. The sync_xxx signals can be used to align the data
// to lines and frames.
//
// The reset_sync output signal mirrors the reset_async input synchronized
// to the output clock signal.
//
// This module is only designed to work with sensors sending 10-bit data
// with a Packetized-SP HiSPi format.
//
// Due to the FPGA primitives used this module is only compatible with
// Xilinx 7-series devices.
// 
//------------------------------------------------------------------------
// Copyright (c) 2017 Opal Kelly Incorporated
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//------------------------------------------------------------------------

`default_nettype none

module syzygy_camera_phy (
	output wire        clk, // derived from hispi clock
	input  wire        reset_async,
	output reg         reset_sync,

	// Camera HiSPi interface
	input  wire [3:0]  slvs_p,
	input  wire [3:0]  slvs_n,
	input  wire        slvsc_p,
	input  wire        slvsc_n,
	output wire        reset_b,

	// Deserialized outputs
	output wire [39:0] pix_data,   // 10 bits per pixel, 4 pixels at a time
	output wire        line_valid, // Pixel data is valid
	output reg  [9:0]  sync_word,  // useful for debug, view sync word 4
	output reg         sync_sof,
	output reg         sync_sol,
	output reg         sync_eol,
	output reg         sync_eof,
	output reg         sync_error // Invalid sync word detected, error
);

// Set the input delay of the SLVS signals to meet timing
// A delay of 14 steps gives ~1.1ns with a 200MHz reference
parameter idelay_val = 14;

wire        clk_out_int, clk_out_bufio, clk_out_div;

reg  [7:0]  reset_serdes_cnt;

// Internal camera data routing signals
wire [3:0]  slvs_p_buf, slvs_p_del;
wire [9:0]  camera_data[3:0]; // data from each lane
wire        iserdes_shift1[3:0];
wire        iserdes_shift2[3:0];

// Synchronization related signals
reg         sync_code_detect, sync_code_detect_reg;
reg  [3:0]  phase;
reg  [3:0]  phase_reg;
wire [39:0] camera_data_aligned[3:0]; // camera data after alignment
reg  [49:0] camera_data_reg_comb[3:0];
reg  [3:0]  pix_data_valid;

assign clk = clk_out_div;
assign reset_b = ~reset_async;
assign line_valid = (&pix_data_valid) & ~sync_code_detect_reg;

// Logic reset, must be held for at least two clock cycles to
// fully reset the ISERDES blocks
always @(posedge clk or posedge reset_async) begin
	if (reset_async == 1'b1) begin
		reset_sync <= 1'b1;
		reset_serdes_cnt <= 8'h10;
	end else begin
		if (reset_serdes_cnt > 00) begin
			reset_serdes_cnt <= reset_serdes_cnt - 1'b1;
			reset_sync <= 1'b1;
		end else begin
			reset_sync <= 1'b0;
		end
	end
end

IBUFDS #(
	.IOSTANDARD ("LVDS_25"),
	.DIFF_TERM  ("TRUE")
) camera_dco (
	.I  (slvsc_p),
	.IB (slvsc_n),
	.O  (clk_out_int)
);

BUFIO camera_bufio (
	.I (clk_out_int),
	.O (clk_out_bufio)
);

BUFR #(
	.SIM_DEVICE  ("7SERIES"),
	.BUFR_DIVIDE ("5")
) camera_bufr (
	.O   (clk_out_div),
	.CE  (1'b1),
	.CLR (reset_async),
	.I   (clk_out_int)
);

always @(*) begin: detect_sync_codes
	integer j;
	integer i;
	reg sync_code_found;

	sync_code_detect = 1'b0;
	phase = 5'h00;

	for (j=9; j >= 0; j=j-1) begin: find_phase
		sync_code_found = 1'b1;
		// check each phase j, if there are 20 zeros we've found the
		// sync word and correct phase
		for (i=0; i<20; i=i+1) begin: find_sync
			if (camera_data_reg_comb[0][j+i] == 1'b1) begin
				sync_code_found = 1'b0;
			end
		end
		
		if (sync_code_found == 1'b1) begin
			phase = j;
			sync_code_detect = 1'b1;
		end
	end
end

// Interpret sync codes
always @(posedge clk_out_div) begin
	if (reset_sync == 1'b1) begin
		sync_sof <= 1'b0;
		sync_sol <= 1'b0;
		sync_eof <= 1'b0;
		sync_eol <= 1'b0;
		sync_error <= 1'b0;
		phase_reg <= 5'h00;
		sync_code_detect_reg <= 1'b0;

		pix_data_valid <= 4'b000;
	end else begin
		sync_sof <= 1'b0;
		sync_sol <= 1'b0;
		sync_eof <= 1'b0;
		sync_eol <= 1'b0;
		sync_error <= 1'b0;

		pix_data_valid <= {pix_data_valid, pix_data_valid[0]};
		
		sync_code_detect_reg <= sync_code_detect;

		if (sync_code_detect == 1'b1) begin
			phase_reg <= phase;
		end
		
		if (sync_code_detect_reg == 1'b1) begin
			pix_data_valid[0] <= 1'b0;
			sync_word <= camera_data_aligned[0][9:0];
			case (camera_data_aligned[0][2:0])
				3'b011: begin
					sync_sof <= 1'b1;
					pix_data_valid[0] <= 1'b1;
				end
				3'b001: begin
					sync_sol <= 1'b1;
					pix_data_valid[0] <= 1'b1;
				end
				3'b111: begin
					sync_eof <= 1'b1;
					pix_data_valid[0] <= 1'b0;
				end
				3'b101: begin
					sync_eol <= 1'b1;
					pix_data_valid[0] <= 1'b0;
				end
				default: begin
					sync_error <= 1'b1;
					pix_data_valid[0] <= 1'b0;
				end
			endcase
		end
	end
end

// Direct connections for each lane
generate
	genvar i;
	for (i=0; i<4; i=i+1) begin: camera_lane_deserial
		genvar j, k;
		for (j=0; j<4; j=j+1) begin
			for (k = 0; k < 10; k=k+1) begin
				assign camera_data_aligned[i][(10*j) + k] = camera_data_reg_comb[i][phase_reg + (10*j) + (9-k)];
			end
		end

		assign pix_data[(i*10)+9:i*10] = camera_data_aligned[i][39:30]; // pull pixel data from the end of the aligned data buffer

		always @(posedge clk_out_div) begin
			if (reset_sync == 1'b1) begin
				camera_data_reg_comb[i] <= 50'h3_ffff_ffff_ffff;
			end else begin
				camera_data_reg_comb[i] <= {camera_data_reg_comb[i], camera_data[i]};
			end
		end


		IBUFDS #(
			.IOSTANDARD ("LVDS_25"),
			.DIFF_TERM  ("TRUE")
		) camera_ibuf (
			.I  (slvs_p[i]),
			.IB (slvs_n[i]),
			.O  (slvs_p_buf[i])
		);

		IDELAYE2 #(
			.IDELAY_TYPE           ("FIXED"),
			.DELAY_SRC             ("IDATAIN"),
			.IDELAY_VALUE          (idelay_val),
			.HIGH_PERFORMANCE_MODE ("TRUE"),
			.SIGNAL_PATTERN        ("DATA"),
			.REFCLK_FREQUENCY      (200),
			.CINVCTRL_SEL          ("FALSE"),
			.PIPE_SEL              ("FALSE")
		) camera_idelayp (
			.C (1'b0),
			.REGRST      (1'b0),
			.LD          (1'b0),
			.CE          (1'b0),
			.INC         (1'b0),
			.CINVCTRL    (1'b0),
			.CNTVALUEIN  (5'h00),
			.IDATAIN     (slvs_p_buf[i]),
			.DATAIN      (1'b0),
			.LDPIPEEN    (1'b0),
			.DATAOUT     (slvs_p_del[i]),
			.CNTVALUEOUT ()
		);

		ISERDESE2 #(
			.DATA_RATE         ("DDR"),
			.DATA_WIDTH        (10),
			.INTERFACE_TYPE    ("NETWORKING"), // Using internal clock network routing
			.DYN_CLKDIV_INV_EN ("FALSE"), // We do not need dynamic clocking
			.DYN_CLK_INV_EN    ("FALSE"), // We do not need dynamic clocking
			.NUM_CE            (1), // Only use CE1 as a clock enable
			.OFB_USED          ("FALSE"),
			.IOBDELAY          ("BOTH"),
			.SERDES_MODE       ("MASTER")
		) camera_serdes1 (
			.Q1        (camera_data[i][0]),
			.Q2        (camera_data[i][1]),
			.Q3        (camera_data[i][2]),
			.Q4        (camera_data[i][3]),
			.Q5        (camera_data[i][4]),
			.Q6        (camera_data[i][5]),
			.Q7        (camera_data[i][6]),
			.Q8        (camera_data[i][7]),
			.O         (),
			.SHIFTOUT1 (iserdes_shift1[i]),
			.SHIFTOUT2 (iserdes_shift2[i]),

			.D         (1'b0),
			.DDLY      (slvs_p_del[i]),

			.CLK       (clk_out_bufio),
			.CLKB      (~clk_out_bufio),
			.CE1       (1'b1),
			.CE2       (1'b0),

			.RST       (reset_sync),

			.CLKDIV    (clk_out_div),
			.CLKDIVP   (1'b0),

			.OCLK      (1'b0),
			.OCLKB     (1'b0),

			.BITSLIP   (1'b0),

			.SHIFTIN1  (1'b0),
			.SHIFTIN2  (1'b0),
			.OFB       (1'b0),
			.DYNCLKDIVSEL (1'b0),
			.DYNCLKSEL    (1'b0)
		);

		ISERDESE2 #(
			.DATA_RATE         ("DDR"),
			.DATA_WIDTH        (10),
			.INTERFACE_TYPE    ("NETWORKING"), // Using internal clock network routing
			.DYN_CLKDIV_INV_EN ("FALSE"), // We do not need dynamic clocking
			.DYN_CLK_INV_EN    ("FALSE"), // We do not need dynamic clocking
			.NUM_CE            (1), // Only use CE1 as a clock enable
			.OFB_USED          ("FALSE"),
			.IOBDELAY          ("BOTH"),
			.SERDES_MODE       ("SLAVE")
		) camera_serdes2 (
			.Q1        (),
			.Q2        (),
			.Q3        (camera_data[i][8]),
			.Q4        (camera_data[i][9]),
			.Q5        (),
			.Q6        (),
			.Q7        (),
			.Q8        (),
			.O         (),
			.SHIFTOUT1 (),
			.SHIFTOUT2 (),

			.D         (1'b0),
			.DDLY      (1'b0),

			.CLK       (~clk_out_bufio),
			.CLKB      (clk_out_bufio),
			.CE1       (1'b1),
			.CE2       (1'b0),

			.RST       (reset_sync),

			.CLKDIV    (clk_out_div),
			.CLKDIVP   (1'b0),

			.OCLK      (1'b0),
			.OCLKB     (1'b0),

			.BITSLIP   (1'b0),

			.SHIFTIN1  (iserdes_shift1[i]),
			.SHIFTIN2  (iserdes_shift2[i]),
			.OFB       (1'b0),
			.DYNCLKDIVSEL (1'b0),
			.DYNCLKSEL    (1'b0)
		);
	end
endgenerate

endmodule
`default_nettype wire

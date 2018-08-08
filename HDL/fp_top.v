//------------------------------------------------------------------------
// fp_top.v
//
// This top level module contains glue logic to connect an HLS module
// generated with Vivado HLS with the FrontPanel interface. A pair of pipe
// endpoints are used for data transfer (with FIFO buffers). Wires and
// triggers are used to manage the HLS module.
//
// Clocking setup:
// + 100.8MHz okClk
//
// FrontPanel Endpoint Usage:
//
// WireIn     0x00     0 - RESET
//
// TriggerIn  0x40     0 - HLS Module Start
//
// WireOut    0x20     0 - HLS Complete
//
// PipeIn     0x80       - HLS Data In
//
// PipeOut    0xA0       - HLS Data Out
//
//------------------------------------------------------------------------
// Copyright (c) 2018 Opal Kelly Incorporated
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
// 
//------------------------------------------------------------------------

`default_nettype none

module fp_top(
	// FrontPanel Connections
	input  wire [4:0]  okUH,
	output wire [3:0]  okHU,
	input  wire [3:0]  okRSVD,
	inout  wire [31:0] okUHU,
	inout  wire        okAA
);

// FrontPanel //
// Target Interface Bus
wire                okClk;
wire [112:0]        okHE;
wire [64:0]         okEH;
wire [65 * 3 - 1:0] okEHx;

// Wire Input //
wire [31:0] wi00;

// Trigger Input //
wire [31:0] ti40;
wire        start_trig;

// Data Pipe Input //
wire [31:0] pipe_in_data;
wire        pipe_in_write;

// Data Pipe Output //
wire [31:0] pipe_out_data;
wire        pipe_out_read;

// Status Output //
wire [31:0] wireout20;

// General //
reg         init_reset     = 1'b1;
reg  [3:0]  reset_count   = 4'd15;
wire        fp_reset;
wire        reset;
reg  [10:0] ap_ready_cnt, hls_reset_cnt;

// Input FIFO //
wire [31:0] a_tdata;
wire        a_tvalid, a_tready;
wire        fifo_in_wr_rst_busy, fifo_in_rd_rst_busy;
wire [10:0] fifo_in_dc;

// HLS Block //
wire       ap_done, ap_idle, ap_ready;
reg        ap_start, ap_rst;

wire [23:0] a_v_tdata;
wire        a_v_tvalid;

// Output FIFO //
wire [47:0] b_tdata;
wire        b_tvalid;
wire        fifo_out_wr_rst_busy, fifo_out_rd_rst_busy;
reg         fifo_out_reset;


assign      reset      = fp_reset | init_reset;

assign      a_v_tdata  = (state == reset_hls) ? 24'd0 : a_tdata;
assign      a_v_tvalid = (state == reset_hls) ? 1'b1 : a_tvalid;

assign      start_trig = ti40[0];

assign      fp_reset   = wi00[0];

// Output whether we're idling or not
assign      wireout20[0] = (state == idle) ? 1'b1 : 1'b0;

// FrontPanel Host Connections
okHost okHI(
	.okUH   (okUH),
	.okHU   (okHU),
	.okRSVD (okRSVD),
	.okUHU  (okUHU),
	.okAA   (okAA),
	.okClk  (okClk),
	.okHE   (okHE), 
	.okEH   (okEH)
);

okWireOR #(.N(3)) wireOR (okEH, okEHx);

okWireIn wireIn00(
	.okHE       (okHE),
	.ep_addr    (8'h00),
	.ep_dataout (wi00)
);

okTriggerIn triggerIn40(
	.okHE       (okHE),
	.ep_addr    (8'h40),
	.ep_clk     (okClk),
	.ep_trigger (ti40)
);

okPipeIn pipeIn80(
	.okHE       (okHE),
	.okEH       (okEHx[0 * 65 +: 65]),
	.ep_addr    (8'h80),

	.ep_write   (pipe_in_write),
	.ep_dataout (pipe_in_data)
);

okPipeOut pipeOutA0(
	.okHE      (okHE),
	.okEH      (okEHx[1 * 65 +: 65]),
	.ep_addr   (8'hA0),

	.ep_datain (pipe_out_data),
	.ep_read   (pipe_out_read)
);

okWireOut wireOut20(
	.okHE      (okHE),
	.okEH      (okEHx[2 * 65 +: 65]),
	.ep_addr   (8'h20),

	.ep_datain (wireout20)
);

axififo_32b1024 fifo_in(
	.s_aclk          (okClk),
	.s_aresetn       (~reset),

	.s_axis_tdata    (pipe_in_data),
	.s_axis_tvalid   (pipe_in_write),
	.s_axis_tready   (),

	.m_axis_tdata    (a_tdata),
	.m_axis_tvalid   (a_tvalid),
	.m_axis_tready   (a_tready),

	.wr_rst_busy     (fifo_in_wr_rst_busy),
	.rd_rst_busy     (fifo_in_rd_rst_busy),

	.axis_data_count (fifo_in_dc)
);

fir_0 fir_inst(
	.ap_clk     (okClk),
	.ap_rst_n   (~(ap_rst | fifo_out_reset)),

	.ap_start   (ap_start),
	.ap_done    (ap_done),
	.ap_idle    (ap_idle),
	.ap_ready   (ap_ready),

	.A_V_TDATA  ({6'h0, a_v_tdata[17:0]}),
	.A_V_TVALID (a_v_tvalid),
	.A_V_TREADY (a_tready),
	
	.B_V_TDATA  (b_tdata),
	.B_V_TVALID (b_tvalid),
	.B_V_TREADY (1'b1)
);

fifo_64b1024_32b2048 fifo_out(
	.clk   (okClk),
	.srst  (fifo_out_reset | reset),

	.din   ({b_tdata[31:0], 16'b0, b_tdata[47:32]}),
	.wr_en (b_tvalid),

	.dout  (pipe_out_data),
	.rd_en (pipe_out_read)
);

// Process Block //
reg  [2:0] state = idle;
localparam idle      = 1,
           running   = 2,
           wait_done = 3,
           reset_hls = 4;
always @(posedge okClk) begin
	if (reset) begin
		state          <= reset_hls;
		ap_ready_cnt   <= 11'd0;
		ap_rst         <= 1'b1;
		ap_start       <= 1'b0;
		fifo_out_reset <= 1'b0;

		if (reset_count == 4'd0) begin
			init_reset <= 1'b0;
		end else begin
			reset_count <= reset_count - 1;
		end
	end else begin
		ap_rst     <= 1'b0;
		ap_start   <= 1'b0;
		fifo_out_reset <= 1'b0;

		if (ap_ready) begin
			ap_ready_cnt <= ap_ready_cnt + 1;
		end

		case (state)
			idle: begin
				if (start_trig) begin
					state        <= running;
					ap_ready_cnt <= 11'd0;
				end
			end

			running: begin
				ap_start <= 1'b1;

				if (ap_ready_cnt == 11'd1023) begin
					state <= wait_done;
				end
			end

			wait_done: begin
				if (ap_done || ap_idle) begin
					state <= idle;
				end
			end

			reset_hls: begin
				ap_start      <= 1'b1;
				if (ap_ready_cnt == 11'd20) begin
					ap_start       <= 1'b0;
					fifo_out_reset <= 1'b1;
					state          <= idle;
				end
			end
		endcase
	end
end

endmodule

`default_nettype wire

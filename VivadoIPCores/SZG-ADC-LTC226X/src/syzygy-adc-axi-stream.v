`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-adc-axi-stream.v
//
// AXI4-Stream manager for the SYZYGY ADC pipeline. Packs {ch1, ch2} into a
// 32-bit TDATA word and crosses adc_clk -> m_axis_aclk through xpm_fifo_async.
// Samples that arrive while the FIFO is full are dropped. TDATA/TVALID/TREADY
// only: the ADC free-runs, so there is no TLAST.
//
//------------------------------------------------------------------------
// Copyright (c) 2026 Opal Kelly Incorporated
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

module syzygy_adc_axi_stream #(
    parameter integer FIFO_DEPTH = 1024   // power-of-two, >= 16
)(
    // ADC-side (write) clock domain
    input  wire        adc_clk,
    input  wire        adc_reset,        // active-high, synchronous to adc_clk
    input  wire        fifo_flush,       // active-high, adc_clk domain: discard buffered samples
    input  wire [15:0] adc_ch1,
    input  wire [15:0] adc_ch2,
    input  wire        adc_data_valid,
    input  wire        adc_ready,

    output wire        overflow_strobe,  // per-drop level (adc_clk); toggle-sync source for CSR

    // AXIS manager (read) clock domain
    input  wire        m_axis_aclk,
    input  wire        m_axis_aresetn,   // active-low
    input  wire        stream_en,        // CSR stream_enable; masks the AXIS output
    output wire        m_axis_tvalid,
    output wire [31:0] m_axis_tdata,
    input  wire        m_axis_tready
);

// ------------------------------------------------------------------
// FIFO reset (adc_clk = wr_clk domain)
// ------------------------------------------------------------------
// xpm_fifo_async requires rst synchronous to wr_clk and at least five wr_clk
// cycles wide. fifo_flush is sampled, and fifo_rst is held FIFO_RST_HOLD cycles
// past the last flush request.
localparam integer FIFO_RST_HOLD = 16;

reg  [4:0] fifo_rst_cnt = FIFO_RST_HOLD[4:0];
always @(posedge adc_clk) begin
    if (fifo_flush)              fifo_rst_cnt <= FIFO_RST_HOLD[4:0];
    else if (fifo_rst_cnt != 0)  fifo_rst_cnt <= fifo_rst_cnt - 1'b1;
end
wire fifo_rst = (fifo_rst_cnt != 5'd0);

// ------------------------------------------------------------------
// Write side (adc_clk)
// ------------------------------------------------------------------
wire        fifo_full;
wire        fifo_empty;
wire        wr_rst_busy;
wire        rd_rst_busy;
wire [31:0] fifo_dout;

// wr_en must be low while wr_rst_busy is high or the FIFO write pointer can be
// corrupted.
wire        wr_en   = adc_ready & adc_data_valid & ~fifo_full & ~wr_rst_busy;
wire [31:0] wr_data = {adc_ch1, adc_ch2};   // ch1 -> [31:16], ch2 -> [15:0]

// High on every cycle a sample is dropped because the FIFO is full.
reg overflow_strobe_r = 1'b0;
always @(posedge adc_clk) begin
    if (adc_reset)
        overflow_strobe_r <= 1'b0;
    else
        overflow_strobe_r <= adc_ready & adc_data_valid & fifo_full & ~wr_rst_busy;
end
assign overflow_strobe = overflow_strobe_r;

// ------------------------------------------------------------------
// Read side (m_axis_aclk)
// ------------------------------------------------------------------
// stream_en low holds TVALID low and stops draining the FIFO, which then
// overflows while the ADC runs. AXI4-Stream forbids dropping TVALID before
// TREADY, so stream_en is sampled only while no beat is pending. A FIFO flush
// (rd_rst_busy) does drop TVALID mid-beat, as a datapath reset.
reg  stream_en_q   = 1'b0;
wire beat_pending  = m_axis_tvalid & ~m_axis_tready;
always @(posedge m_axis_aclk) begin
    if (!m_axis_aresetn)    stream_en_q <= 1'b0;
    else if (!beat_pending) stream_en_q <= stream_en;
end

// rd_en must be low while rd_rst_busy is high.
wire rd_en = stream_en_q & m_axis_tready & ~fifo_empty & ~rd_rst_busy;

assign m_axis_tdata  = fifo_dout;
assign m_axis_tvalid = stream_en_q & ~fifo_empty & ~rd_rst_busy;

xpm_fifo_async #(
    .FIFO_MEMORY_TYPE   ("auto"),
    .FIFO_WRITE_DEPTH   (FIFO_DEPTH),
    .WRITE_DATA_WIDTH   (32),
    .READ_DATA_WIDTH    (32),
    .READ_MODE          ("fwft"), // dout valid when ~empty; matches the combinational read side
    .FIFO_READ_LATENCY  (0),      // must be 0 for fwft
    .CDC_SYNC_STAGES    (2),
    .RELATED_CLOCKS     (0),
    .USE_ADV_FEATURES   ("0000"),
    .WAKEUP_TIME        (0)
) fifo_inst (
    .rst            (fifo_rst),
    .wr_clk         (adc_clk),
    .wr_en          (wr_en),
    .din            (wr_data),
    .full           (fifo_full),
    .wr_ack         (),
    .overflow       (),
    .wr_rst_busy    (wr_rst_busy),
    .almost_full    (),
    .wr_data_count  (),
    .prog_full      (),

    .rd_clk         (m_axis_aclk),
    .rd_en          (rd_en),
    .dout           (fifo_dout),
    .empty          (fifo_empty),
    .underflow      (),
    .rd_rst_busy    (rd_rst_busy),
    .almost_empty   (),
    .rd_data_count  (),
    .prog_empty     (),
    .data_valid     (),

    .injectsbiterr  (1'b0),
    .injectdbiterr  (1'b0),
    .sbiterr        (),
    .dbiterr        (),

    .sleep          (1'b0)
);

endmodule
`default_nettype wire

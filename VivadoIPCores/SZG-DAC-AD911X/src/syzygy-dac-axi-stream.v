`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-dac-axi-stream.v
//
// AXI4-Stream subordinate + clock-crossing buffer for the SYZYGY DAC pipeline.
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

module syzygy_dac_axi_stream #(
    parameter integer FIFO_DEPTH = 32,   // power-of-two, >= 16
    // Idle code in the device's CONFIGURED format -- the DAC_RESET_VALUE parameter
    // on syzygy_dac. Applies once fmt_applied is set; IDLE_CODE_POR covers before.
    parameter [11:0]  DAC_IDLE_CODE = 12'h800
)(
    // AXI4-Stream subordinate (write) clock domain
    input  wire        s_axis_aclk,
    input  wire        core_reset,       // active-high; FIFO write-side reset
    output wire        s_axis_tready,
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,

    // DAC sample (read) clock domain
    input  wire        dac_sample_clk,
    input  wire        sample_reset,     // active-high, dac_sample_clk domain
    input  wire        fmt_applied,      // sync'd to dac_sample_clk by the top level:
                                         // the Data Control write has landed, so the
                                         // device is in DAC_IDLE_CODE's format
    output reg  [23:0] sample,           // drained {I[23:12], Q[11:0]} pair to the PHY (held on underflow)
    output wire        underflow_strobe  // per-empty level (dac_sample_clk); toggle-sync source for CSR
);

// Mid-scale in the AD911x's power-on (offset binary) format -- see idle_code below.
localparam [11:0] IDLE_CODE_POR = 12'h800;

// ------------------------------------------------------------------
// Write side (s_axis_aclk): FIFO write.
// ------------------------------------------------------------------
wire        fifo_full;
wire        fifo_wr_rst_busy;
wire        fifo_empty;
wire [23:0] fifo_dout;

// Two 12-bit samples per 32-bit beat, each MSB-aligned (left-justified) in its
// half-word: channel I = s_axis_tdata[31:20], channel Q = s_axis_tdata[15:4]
//
// The pair is packed {I,Q} into one FIFO word so the two channels stay
// sample-aligned across the CDC.
wire [11:0] wr_data_i = s_axis_tdata[31:20];
wire [11:0] wr_data_q = s_axis_tdata[15:4];
wire [23:0] wr_data   = {wr_data_i, wr_data_q};

// Accept data whenever the FIFO can take it -- not full and not in reset -- and
// push on an accepted beat. Holding tready low while wr_rst_busy is asserted keeps
// the adapter from ACK-ing beats the FIFO would silently drop during a (soft)
// reset, and keeps wr_en from pulsing into a FIFO that is still resetting.
assign s_axis_tready = ~fifo_full & ~fifo_wr_rst_busy;
wire   wr_en         = s_axis_tvalid & s_axis_tready;

// ------------------------------------------------------------------
// Async CDC FIFO: s_axis_aclk (write) -> dac_sample_clk (read).
// FWFT read; one sample drained per dac_sample_clk while data is available.
// ------------------------------------------------------------------
xpm_fifo_async #(
    .FIFO_MEMORY_TYPE  ("auto"),
    .FIFO_WRITE_DEPTH  (FIFO_DEPTH),
    .WRITE_DATA_WIDTH  (24),
    .READ_DATA_WIDTH   (24),
    .READ_MODE         ("fwft"),
    .FIFO_READ_LATENCY (0),
    .CDC_SYNC_STAGES   (2),
    .RELATED_CLOCKS    (0),
    .USE_ADV_FEATURES  ("0000"),
    .ECC_MODE          ("no_ecc"),
    .DOUT_RESET_VALUE  ("0"),
    .WAKEUP_TIME       (0)
) dac_cdc_fifo (
    .wr_clk        (s_axis_aclk),
    .rst           (core_reset),
    .din           (wr_data),
    .wr_en         (wr_en),
    .full          (fifo_full),
    .almost_full   (),
    .prog_full     (),
    .wr_data_count (),
    .overflow      (),
    .wr_ack        (),
    .wr_rst_busy   (fifo_wr_rst_busy),

    .rd_clk        (dac_sample_clk),
    .rd_en         (~fifo_empty),
    .dout          (fifo_dout),
    .empty         (fifo_empty),
    .almost_empty  (),
    .prog_empty    (),
    .rd_data_count (),
    .underflow     (),
    .data_valid    (),
    .rd_rst_busy   (),

    .injectsbiterr (1'b0),
    .injectdbiterr (1'b0),
    .sbiterr       (),
    .dbiterr       (),
    .sleep         (1'b0)
);

// ------------------------------------------------------------------
// Read side (dac_sample_clk): drain one {I,Q} pair per clock; hold last on
// underflow (empty). underflow_strobe is the registered empty level.
// ------------------------------------------------------------------
//
wire [11:0] idle_code = fmt_applied ? DAC_IDLE_CODE : IDLE_CODE_POR;

reg seen_data;
always @(posedge dac_sample_clk) begin
    if (sample_reset)     seen_data <= 1'b0;
    else if (~fifo_empty) seen_data <= 1'b1;
end

always @(posedge dac_sample_clk) begin
    if (sample_reset)     sample <= {IDLE_CODE_POR, IDLE_CODE_POR};
    else if (~fifo_empty) sample <= fifo_dout;
    else if (!seen_data)  sample <= {idle_code, idle_code};
end

reg fifo_empty_d = 1'b0;
always @(posedge dac_sample_clk) begin
    if (sample_reset) fifo_empty_d <= 1'b0;
    else              fifo_empty_d <= fifo_empty;
end
assign underflow_strobe = fifo_empty_d;

endmodule

`default_nettype wire

`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy_adc.v
//
// Top-level module for the Opal Kelly SYZYGY ADC IP (LTC2264-12 /
// LTC2268-14). The DCO drives the ISERDES capture clocks through BUFGCE_DIV
// with no MMCM, and the IDELAYE3 lanes run in COUNT mode with EN_VTC Low, so
// the IP has no IDELAYCTRL (UG571 p168).
//------------------------------------------------------------------------
// Copyright (c) 2021-2026 Opal Kelly Incorporated
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

module syzygy_adc #
(
    // ADC variant select (enum): 0 = LTC2264-12 (12-bit, 40 MSPS),
    // 1 = LTC2268-14 (14-bit, 125 MSPS). Not read by this RTL. It sets the
    // ADC_SAMPLE_CLK FREQ_HZ that component.xml propagates in IP Integrator.
    parameter integer ADC_VARIANT = 1,

    // Depth of the async FIFO that crosses adc_data_clk -> aclk.
    // Must be a power of two and >= 16.
    parameter integer FIFO_DEPTH = 1024,

    // Control/status interface select (enum):
    //   0 = AXI4-Lite CSR (s_axi_csr)
    //   1 = Discrete control/status pins
    parameter integer CTRL_INTERFACE = 0,

    // Alignment mode at reset (enum):
    //   0 = One-shot: align at bring-up and on each re-align, then hold the tap.
    //   1 = Continual: after each alignment, keep tracking the eye.
    // In CSR mode this is only the reset value of TRACK_CTRL[0], and STATUS[10]
    // reads it back. In discrete mode it fixes the mode, with the TRACK_CTRL
    // reset settings.
    parameter integer ALIGN_MODE = 0,

    parameter integer C_M_AXIS_TDATA_WIDTH = 32
)
(
    // SZG-ADC LVDS data lanes
    input  wire [1:0]  adc_data_1p,
    input  wire [1:0]  adc_data_1n,
    input  wire [1:0]  adc_data_2p,
    input  wire [1:0]  adc_data_2n,
    input  wire        adc_dco_p,
    input  wire        adc_dco_n,
    input  wire        adc_fr_p,
    input  wire        adc_fr_n,
    output wire        adc_encode_p,
    output wire        adc_encode_n,

    // SZG-ADC SPI (4-wire). The LTC register set is reachable from the CSR
    // (offsets 0x40+). With no CSR writes the LTC runs on its power-on defaults.
    input  wire        adc_sdo,   // ADC -> FPGA (register read-back)
    output wire        adc_sdi,   // FPGA -> ADC (configuration)
    output wire        adc_cs_n,
    output wire        adc_sclk,

    // Sample/encode clock. The LTC samples on the encode edge, so the sample and
    // encode clocks are the same signal. Independent of aclk.
    input  wire        adc_sample_clk,

    // AXI4-Lite control/status (s_axi_csr), present when CTRL_INTERFACE = 0.
    // aclk domain.
    input  wire [11:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [11:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

    // Discrete control/status, present when CTRL_INTERFACE = 1. Active-high,
    // aclk domain.
    input  wire        ctrl_realign,      // CTRL[0]: re-align/reset (1-cycle strobe)
    input  wire        ctrl_stream_en,    // CTRL[2]: stream enable (level)
    input  wire        ctrl_clear_flags,  // CTRL[8]: clear sticky flags (1-cycle strobe)
    output wire        adc_ready,         // STATUS[0]
    output wire        capture_clk_alive, // STATUS[1]
    output wire        align_done,        // STATUS[2]
    output wire        align_fail,        // STATUS[3]
    output wire        fifo_overflow,     // STATUS[4] (sticky; cleared by ctrl_clear_flags)
    output wire        frame_error,       // STATUS[7] (sticky; cleared by ctrl_clear_flags)
    output wire [15:0] align_phase,       // ALIGN[15:0]
    output wire [15:0] eye_width,         // ALIGN[31:16]

    // Clock/reset for both the AXIS manager and the AXI4-Lite CSR
    input  wire                                    aclk,
    input  wire                                    aresetn,
    output wire                                    m_axis_tvalid,
    output wire [C_M_AXIS_TDATA_WIDTH-1 : 0]     m_axis_tdata,
    input  wire                                    m_axis_tready
);

// ------------------------------------------------------------------
// ADC physical layer (adc_data_clk domain). Default LTC output mode:
// 2-lane, 16-bit serialization.
// ------------------------------------------------------------------
wire        adc_data_clk;
wire [15:0] adc_ch1;
wire [15:0] adc_ch2;
wire        adc_data_valid;

wire        adc_bufio_clk;
wire [3:0]  bitslip_count;
wire        frame_ok;

// IDELAYE3 tap control from idelay_align (VAR_LOAD / COUNT). data_* drives every
// data lane, frame_* the frame lane. They carry the same tap except while the
// tracker probes the frame lane. pa_* are the align outputs in the adc_data_clk
// domain; only their aclk-synchronized sts_* copies reach the CSR and pins.
wire [8:0]  data_tap;
wire        data_load;
wire [8:0]  frame_tap;
wire        frame_load;
wire        pa_done;
wire        pa_fail;
wire [15:0] pa_phase;
wire [15:0] pa_eye_width;
// Per-tap map of the last sweep (width = ALIGN_SWEEP_TAPS) and the taps the
// IDELAYE3s hold (CNTVALUEOUT).
wire [511:0] pa_good_map;
wire [8:0]   frame_tap_cnt;
wire [8:0]   data_tap_cnt;      // ch1 lane 1
// Tracking (adc_data_clk domain)
wire         pa_bitslip_freeze;
wire         pa_trk_busy;
wire [15:0]  pa_trk_count;
wire [7:0]   pa_trk_last_move;
wire [7:0]   pa_trk_err_count;
wire [8:0]   pa_trk_left;
wire [8:0]   pa_trk_right;

// Core control nets (aclk domain). Driven by the CSR adapter or the discrete
// control pins, selected by CTRL_INTERFACE in the generate block below.
wire        ctrl_realign_pulse;
wire        ctrl_stream_enable;
// Manual tap override request (aclk domain, levels): TAP_CTRL in CSR mode, tied
// off in discrete mode.
wire        ctrl_ovr_en;
wire [8:0]  ctrl_ovr_tap;
wire        pa_ovr_active;    // adc_data_clk domain, from idelay_align
wire        sts_ovr_active;   // synchronized into aclk (STATUS[8])
// Tracking controls (aclk domain, levels): TRACK_CTRL in CSR mode, set by
// ALIGN_MODE in discrete mode.
localparam ALIGN_CONTINUAL = (ALIGN_MODE != 0);
wire        ctrl_trk_en;
wire [3:0]  ctrl_trk_deadband;
wire [7:0]  ctrl_trk_offset;
wire [15:0] ctrl_trk_interval;

// Status synchronized into the aclk (CSR) domain
wire        sts_adc_ready;
wire        sts_capture_clk_alive;
wire        sts_align_done;
wire        sts_align_fail;
wire        sts_overflow_set;
wire        sts_frame_err_set;
wire [15:0] sts_align_phase;
wire [15:0] sts_eye_width;
wire [8:0]   sts_live_tap;      // frame tap
wire [8:0]   sts_data_tap;
wire [511:0] sts_eye_map;
wire         sts_trk_busy;
wire [15:0]  sts_trk_count;
wire [7:0]   sts_trk_last_move;
wire [7:0]   sts_trk_err_count;
wire [8:0]   sts_trk_left;
wire [8:0]   sts_trk_right;

wire        overflow_strobe;   // level: high each adc_data_clk cycle a sample is dropped

// adc_data_clk cycles the SERDES is held after the pipeline reset releases, so
// the ISERDES settles before data is trusted.
localparam [6:0] SERDES_WAIT = 7'd64;

reg         reset_sync        = 1'b1;   // SERDES/PHY reset; held active out of config
reg         clock_rdy         = 1'b0;
reg [6:0]   reset_serdes_cnt  = SERDES_WAIT;
reg         reset_serdes_hold = 1'b0;

// ------------------------------------------------------------------
// Pipeline reset generation.
//
// The ADC pipeline re-sequences on system reset (~aresetn) and on the one-cycle
// CTRL[0] re-align strobe. Either trigger is stretched to RESET_STRETCH aclk
// cycles so the pipeline reset spans several adc_data_clk periods, long enough
// for the reset synchronizer below and for the FIFO flush minimum width.
// ------------------------------------------------------------------
localparam integer RESET_STRETCH = 64;
localparam integer RST_CNT_WIDTH = $clog2(RESET_STRETCH + 1);
reg  [RST_CNT_WIDTH-1:0] rst_cnt = RESET_STRETCH[RST_CNT_WIDTH-1:0];
wire           sys_reset = ~aresetn;   // active-high system reset (aclk domain)

always @(posedge aclk) begin
    if (sys_reset)               rst_cnt <= RESET_STRETCH[RST_CNT_WIDTH-1:0];
    else if (ctrl_realign_pulse) rst_cnt <= RESET_STRETCH[RST_CNT_WIDTH-1:0];  // CSR CTRL[0] one-shot
    else if (rst_cnt != 0)       rst_cnt <= rst_cnt - 1'b1;
end

wire reset_async = sys_reset | (rst_cnt != 0);   // aclk domain

// 2-FF reset synchronizer into adc_data_clk: async assert, sync de-assert.
(* ASYNC_REG = "TRUE" *) reg [1:0] reset_adc_sync = 2'b11;
always @(posedge adc_data_clk or posedge reset_async) begin
    if (reset_async) reset_adc_sync <= 2'b11;
    else             reset_adc_sync <= {reset_adc_sync[0], 1'b0};
end
wire reset_adc = reset_adc_sync[1];

// clock_rdy: the SERDES is out of reset and the bit-slip pipeline is live; the
// alignment FSM starts on it. data_rdy additionally requires alignment and gates
// adc_ready and the AXI stream.
wire        data_rdy = clock_rdy & pa_done;

// ------------------------------------------------------------------
// SPI register plane (aclk domain): LTC2264/LTC2268 configuration and live
// register read-back, exposed through the CSR at offsets 0x40+.
//
// The SPI plane resets on the same stretched pipeline reset as the capture path,
// so a CTRL[0] re-align clears the shadow registers. It does not issue an LTC
// RESET, so the silicon keeps its register state. CTRL[9] spi_reconfig re-pushes
// the shadowed config without a re-align.
// ------------------------------------------------------------------
wire spi_reset = reset_async;   // aclk-domain, active-high (system reset | CTRL[0])

wire [6:0]  spi_reg;
wire [7:0]  spi_data_in, spi_data_out;
wire        spi_send, spi_done, spi_rw;

// SPI control-plane <-> CSR nets (aclk domain). Driven by the CSR adapter in
// g_csr, or tied off in g_discrete (discrete mode leaves the LTC at defaults).
wire        spi_reconfig;      // CTRL[9] re-apply device config
wire        reg_we;            // raw device-register write strobe
wire [6:0]  reg_waddr;
wire [7:0]  reg_wdata;
wire        reg_rreq;          // live device-register read request
wire [6:0]  reg_raddr;
wire [7:0]  reg_rdata;         // live read data (controller -> CSR)
wire        reg_rerr;          // live read watchdog timeout -> SLVERR
wire        reg_rvalid;        // live read done strobe
wire        adc_spi_ready;     // SPI bring-up flush complete -> STATUS[5]
wire        spi_busy;          // controller/engine active -> STATUS[6]

// SCLK = aclk / (2 * (SCLK_DIV + 1)). LTC SCLK max is ~20 MHz.
localparam integer SCLK_DIV = 100;

syzygy_adc_spi #(
    .SCLK_DIV     (SCLK_DIV)
) adc_spi (
    .clk          (aclk),
    .reset        (spi_reset),

    .adc_sclk     (adc_sclk),     // ADC SPI clock pad
    .adc_sdi      (adc_sdi),      // ADC SPI data in  pad (FPGA -> ADC)
    .adc_sdo      (adc_sdo),      // ADC SPI data out pad (ADC -> FPGA)
    .adc_cs_n     (adc_cs_n),     // ADC chip select pad (active low)

    .spi_reg      (spi_reg),      // LTC register address
    .spi_data_in  (spi_data_in),  // data to LTC
    .spi_data_out (spi_data_out), // data from LTC (live register reads)
    .spi_send     (spi_send),     // start command
    .spi_done     (spi_done),     // command complete, data_out valid
    .spi_rw       (spi_rw)        // read or write
);

syzygy_adc_spi_ctrl adc_spi_ctrl (
    .clk         (aclk),
    .reset       (spi_reset),

    .reconfig    (spi_reconfig),

    // Raw register write port + live read port (from the CSR direct map).
    .reg_waddr   (reg_waddr),
    .reg_wdata   (reg_wdata),
    .reg_we      (reg_we),
    .reg_raddr   (reg_raddr),
    .reg_rreq    (reg_rreq),
    .reg_rdata   (reg_rdata),
    .reg_rerr    (reg_rerr),
    .reg_rvalid  (reg_rvalid),

    .spi_ready   (adc_spi_ready),  // aclk domain -> STATUS[5]
    .spi_busy    (spi_busy),

    .spi_reg     (spi_reg),
    .spi_data_in (spi_data_in),
    .spi_send    (spi_send),
    .spi_done    (spi_done),
    .spi_data_out(spi_data_out),
    .spi_rw      (spi_rw)
);

// ------------------------------------------------------------------
// Capture-clock health monitor -> STATUS[1] (capture_clk_alive)
//
// adc_data_clk comes from the pod's DCO and stops if the pod is absent,
// unpowered, or not outputting a DCO. A toggle in the capture domain is
// resynchronized into aclk and edge-detected; with no edge for
// CLK_ALIVE_TIMEOUT aclk cycles the clock is declared dead. Not reset by
// reset_async, so it reports the DCO while the datapath is held in reset.
// ------------------------------------------------------------------
// The terminal count must stay the counter's all-ones value. An integer that
// does not fit CLK_ALIVE_CNT_W truncates to 0 and makes the bit follow dco_edge.
localparam integer                       CLK_ALIVE_CNT_W   = 12;   // ~41 us @ 100 MHz aclk
localparam [CLK_ALIVE_CNT_W-1:0]         CLK_ALIVE_TIMEOUT = {CLK_ALIVE_CNT_W{1'b1}};

reg dco_tgl = 1'b0;
always @(posedge adc_data_clk) dco_tgl <= ~dco_tgl;

(* ASYNC_REG = "TRUE" *) reg [2:0] dco_tgl_sync = 3'b000;
always @(posedge aclk) dco_tgl_sync <= {dco_tgl_sync[1:0], dco_tgl};
wire dco_edge = dco_tgl_sync[2] ^ dco_tgl_sync[1];

reg [CLK_ALIVE_CNT_W-1:0] dco_wd_cnt          = {CLK_ALIVE_CNT_W{1'b0}};
reg                       capture_clk_alive_r = 1'b0;
always @(posedge aclk) begin
    if (dco_edge) begin
        dco_wd_cnt          <= {CLK_ALIVE_CNT_W{1'b0}};
        capture_clk_alive_r <= 1'b1;
    end
    else if (dco_wd_cnt != CLK_ALIVE_TIMEOUT)
        dco_wd_cnt          <= dco_wd_cnt + 1'b1;
    else
        capture_clk_alive_r <= 1'b0;
end

// Reset sequencing: hold the SERDES/PHY in reset (reset_sync) while reset_adc is
// asserted, then release it and wait SERDES_WAIT adc_data_clk cycles before
// setting clock_rdy.
always @(posedge adc_data_clk or posedge reset_adc) begin
    if (reset_adc == 1'b1) begin
        reset_sync        <= 1'b1;
        clock_rdy         <= 1'b0;
        reset_serdes_hold <= 1'b0;
        reset_serdes_cnt  <= SERDES_WAIT;
    end
    else begin
        if (reset_sync) begin
            reset_sync        <= 1'b0;
            clock_rdy         <= 1'b0;
            reset_serdes_hold <= 1'b1;
            reset_serdes_cnt  <= SERDES_WAIT;
        end
        if (reset_serdes_hold) begin
            if (reset_serdes_cnt != 7'd0) begin
                reset_serdes_cnt <= reset_serdes_cnt - 1'b1;
                clock_rdy        <= 1'b0;
            end
            else begin
                clock_rdy         <= 1'b1;
                reset_serdes_hold <= 1'b0;
            end
        end
    end
end

syzygy_adc_phy adc_phy_ch1 (
    .reset         (reset_sync),
    .ena           (clock_rdy),
    .adc_data_p    (adc_data_1p),
    .adc_data_n    (adc_data_1n),
    .adc_bufio_clk (adc_bufio_clk),
    .adc_data_clk  (adc_data_clk),
    .bitslip_count (bitslip_count),
    .idelay_clk    (adc_data_clk),
    .idelay_tap    (data_tap),
    .idelay_load   (data_load),
    .idelay_cntvalue (data_tap_cnt),
    .adc_data_out  (adc_ch1)
);

syzygy_adc_phy adc_phy_ch2 (
    .reset         (reset_sync),
    .ena           (clock_rdy),
    .adc_data_p    (adc_data_2p),
    .adc_data_n    (adc_data_2n),
    .adc_bufio_clk (adc_bufio_clk),
    .adc_data_clk  (adc_data_clk),
    .bitslip_count (bitslip_count),
    .idelay_clk    (adc_data_clk),
    .idelay_tap    (data_tap),
    .idelay_load   (data_load),
    .idelay_cntvalue (),
    .adc_data_out  (adc_ch2)
);

syzygy_adc_dco adc_dco_impl (
    .adc_dco_p     (adc_dco_p),
    .adc_dco_n     (adc_dco_n),
    .clk_out_bufio (adc_bufio_clk),
    .clk_out_div   (adc_data_clk)
);

syzygy_adc_frame adc_frame_impl (
    .adc_data_clk  (adc_data_clk),
    .reset         (reset_sync),
    .adc_bufio_clk (adc_bufio_clk),
    .adc_fr_p      (adc_fr_p),
    .adc_fr_n      (adc_fr_n),
    .bitslip_count (bitslip_count),
    .ena           (clock_rdy),
    .idelay_clk    (adc_data_clk),
    .idelay_tap    (frame_tap),
    .idelay_load   (frame_load),
    .idelay_cntvalue (frame_tap_cnt),
    .frame_ok      (frame_ok),
    .data_valid    (adc_data_valid),
    .bitslip_freeze (pa_bitslip_freeze)
);

// ------------------------------------------------------------------
// Eye centering
//
// idelay_align sweeps the IDELAYE3 taps at bring-up to center the data eye in
// the ISERDES capture window, using frame_ok as the per-tap quality signal. The
// fabric bitslip handles whole-UI alignment; the sweep centers the sub-UI eye.
// ------------------------------------------------------------------
localparam integer ALIGN_SWEEP_TAPS = 512;
localparam integer ALIGN_MIN_EYE    = 32;

// Override request crossing, aclk -> adc_data_clk. {en, tap} only changes on a
// host register write. It passes two synchronizer stages and is taken only when
// two consecutive samples agree, which requires the bus skew to stay under one
// adc_data_clk period (set_bus_skew in the IP XDC).
(* ASYNC_REG = "TRUE" *) reg [9:0] ovr_req_meta = 10'd0;
(* ASYNC_REG = "TRUE" *) reg [9:0] ovr_req_s1   = 10'd0;
reg [9:0] ovr_req_s2  = 10'd0;
reg [9:0] ovr_req_adc = 10'd0;   // {en, tap} as seen by idelay_align
always @(posedge adc_data_clk) begin
    ovr_req_meta <= {ctrl_ovr_en, ctrl_ovr_tap};
    ovr_req_s1   <= ovr_req_meta;
    ovr_req_s2   <= ovr_req_s1;
    if (ovr_req_s1 == ovr_req_s2)
        ovr_req_adc <= ovr_req_s2;
end

// Tracking controls, aclk -> adc_data_clk: the same double-sample crossing as
// the override request.
(* ASYNC_REG = "TRUE" *) reg [28:0] trk_req_meta = 29'd0;
(* ASYNC_REG = "TRUE" *) reg [28:0] trk_req_s1   = 29'd0;
reg [28:0] trk_req_s2  = 29'd0;
reg [28:0] trk_req_adc = 29'd0;   // {en, deadband[3:0], offset[7:0], interval[15:0]}
always @(posedge adc_data_clk) begin
    trk_req_meta <= {ctrl_trk_en, ctrl_trk_deadband, ctrl_trk_offset, ctrl_trk_interval};
    trk_req_s1   <= trk_req_meta;
    trk_req_s2   <= trk_req_s1;
    if (trk_req_s1 == trk_req_s2)
        trk_req_adc <= trk_req_s2;
end

idelay_align #(
    .SWEEP_TAPS   (ALIGN_SWEEP_TAPS),
    .MIN_EYE_TAPS (ALIGN_MIN_EYE)
) adc_align_impl (
    .clk           (adc_data_clk),
    .reset         (reset_sync),
    .start         (clock_rdy),
    .data_ok       (frame_ok),
    .data_tap      (data_tap),
    .data_load     (data_load),
    .frame_tap     (frame_tap),
    .frame_load    (frame_load),
    .align_done    (pa_done),
    .align_fail    (pa_fail),
    .align_phase   (pa_phase),
    .eye_width     (pa_eye_width),
    .good_map      (pa_good_map),
    .ovr_en        (ovr_req_adc[9]),
    .ovr_tap       (ovr_req_adc[8:0]),
    .ovr_active    (pa_ovr_active),
    .trk_en        (trk_req_adc[28]),
    .trk_deadband  (trk_req_adc[27:24]),
    .trk_offset    (trk_req_adc[23:16]),
    .trk_interval  (trk_req_adc[15:0]),
    .bitslip_freeze(pa_bitslip_freeze),
    .trk_busy      (pa_trk_busy),
    .trk_count     (pa_trk_count),
    .trk_last_move (pa_trk_last_move),
    .trk_err_count (pa_trk_err_count),
    .trk_left      (pa_trk_left),
    .trk_right     (pa_trk_right)
);

syzygy_adc_enc adc_enc_impl (
    .clk          (adc_sample_clk),
    .adc_encode_p (adc_encode_p),
    .adc_encode_n (adc_encode_n)
);

// ------------------------------------------------------------------
// AXI-Stream manager with async FIFO crossing adc_data_clk -> aclk
// ------------------------------------------------------------------
wire [C_M_AXIS_TDATA_WIDTH-1:0] m_axis_tdata_raw;

syzygy_adc_axi_stream #(
    .FIFO_DEPTH       (FIFO_DEPTH)
) adc_axi_stream_impl (
    .adc_clk          (adc_data_clk),
    .adc_reset        (~data_rdy),
    // Flush on every pipeline re-sequence so pre-align samples are discarded.
    .fifo_flush       (reset_adc),
    .adc_ch1          (adc_ch1),
    .adc_ch2          (adc_ch2),
    .adc_data_valid   (adc_data_valid),
    .adc_ready        (data_rdy),

    .overflow_strobe  (overflow_strobe),

    .m_axis_aclk      (aclk),
    .m_axis_aresetn   (aresetn),
    .stream_en        (ctrl_stream_enable),
    .m_axis_tvalid    (m_axis_tvalid),
    .m_axis_tdata     (m_axis_tdata_raw),
    .m_axis_tready    (m_axis_tready)
);

// ------------------------------------------------------------------
// Output sample format.
//
// The packed word is {ch1[31:16], ch2[15:0]}, signed two's complement. Flipping
// the MSB of each half-word converts the LTC offset-binary (mid-scale 0x8000) to
// signed. The 0x8000_8000 mask assumes C_M_AXIS_TDATA_WIDTH == 32.
// ------------------------------------------------------------------
assign m_axis_tdata = m_axis_tdata_raw ^ 32'h8000_8000;

// ------------------------------------------------------------------
// Status clock-domain crossing: adc_data_clk -> aclk (CSR domain)
// ------------------------------------------------------------------
// Single-bit levels: 2-FF synchronizers.
(* ASYNC_REG = "TRUE" *) reg [1:0] rdy_sync  = 2'b00;
(* ASYNC_REG = "TRUE" *) reg [1:0] done_sync = 2'b00;
(* ASYNC_REG = "TRUE" *) reg [1:0] fail_sync = 2'b00;
always @(posedge aclk) begin
    rdy_sync  <= {rdy_sync [0], data_rdy};
    done_sync <= {done_sync[0], pa_done};
    fail_sync <= {fail_sync[0], pa_fail};
end
assign sts_adc_ready   = rdy_sync [1];
assign sts_align_done  = done_sync[1];
assign sts_align_fail  = fail_sync[1];

// Override engaged: a single-bit level, 2-FF synchronizer.
(* ASYNC_REG = "TRUE" *) reg [1:0] ovr_act_sync = 2'b00;
always @(posedge aclk) ovr_act_sync <= {ovr_act_sync[0], pa_ovr_active};
assign sts_ovr_active = ovr_act_sync[1];

// STATUS[1] is generated in aclk by the watchdog above.
assign sts_capture_clk_alive = capture_clk_alive_r;

// Eye map: frozen in both S_DONE and S_FAIL, so it is captured while either
// synced flag is high. Valid only while align_done or align_fail is set.
reg [511:0] eye_map_cap = 512'd0;
always @(posedge aclk) begin
    if (sts_align_done | sts_align_fail)
        eye_map_cap <= pa_good_map;
end
assign sts_eye_map = eye_map_cap;

// Status snapshot: ALIGN, both live taps and the tracker telemetry cross as one
// bundle so the CSR sees a coherent set. Every 16 adc_data_clk cycles the bundle
// is copied into snap_hold and snap_tgl flips; aclk edge-detects the toggle
// through a 3-FF synchronizer and samples snap_hold, which stays stable for 16
// adc_data_clk cycles (128 ns on the -14). The XDC bounds the bundle skew with
// set_bus_skew. If the DCO stops, the last values are held.
localparam integer SNAP_W = 16 + 16 + 9 + 9 + 1 + 16 + 8 + 8 + 9 + 9;   // 101
reg [SNAP_W-1:0] snap_hold = {SNAP_W{1'b0}};
reg [3:0]        snap_div  = 4'd0;
reg              snap_tgl  = 1'b0;
always @(posedge adc_data_clk) begin
    snap_div <= snap_div + 1'b1;
    if (snap_div == 4'd0) begin
        snap_hold <= {pa_phase, pa_eye_width, frame_tap_cnt, data_tap_cnt, pa_trk_busy,
                      pa_trk_count, pa_trk_last_move, pa_trk_err_count,
                      pa_trk_left, pa_trk_right};
        snap_tgl  <= ~snap_tgl;
    end
end
(* ASYNC_REG = "TRUE" *) reg [2:0] snap_tgl_sync = 3'd0;
reg [SNAP_W-1:0] snap_cap = {SNAP_W{1'b0}};
always @(posedge aclk) begin
    snap_tgl_sync <= {snap_tgl_sync[1:0], snap_tgl};
    if (snap_tgl_sync[2] ^ snap_tgl_sync[1])
        snap_cap <= snap_hold;
end
assign {sts_align_phase, sts_eye_width, sts_live_tap, sts_data_tap, sts_trk_busy,
        sts_trk_count, sts_trk_last_move, sts_trk_err_count,
        sts_trk_left, sts_trk_right} = snap_cap;

// Overflow events: ovf_tgl flips on each adc_data_clk cycle a sample is dropped,
// and a 3-FF synchronizer edge-detects it into a set pulse in aclk. While
// overflow persists the pulse keeps firing, so clear_flags against a full FIFO
// re-asserts the sticky flag.
reg ovf_tgl = 1'b0;
always @(posedge adc_data_clk) begin
    if (overflow_strobe) ovf_tgl <= ~ovf_tgl;
end
(* ASYNC_REG = "TRUE" *) reg [2:0] ovf_tgl_sync = 3'd0;
always @(posedge aclk) begin
    ovf_tgl_sync <= {ovf_tgl_sync[1:0], ovf_tgl};
end
assign sts_overflow_set = ovf_tgl_sync[2] ^ ovf_tgl_sync[1];

// Frame-word health after alignment -> STATUS[7]. Any frame_ok drop after
// pa_done means the capture link degraded. Same toggle handshake as overflow.
reg frame_err_tgl = 1'b0;
always @(posedge adc_data_clk) begin
    // The tracker drives the frame lane into its error bands while probing.
    if (pa_done & ~frame_ok & ~pa_trk_busy) frame_err_tgl <= ~frame_err_tgl;
end
(* ASYNC_REG = "TRUE" *) reg [2:0] frame_err_tgl_sync = 3'd0;
always @(posedge aclk) begin
    frame_err_tgl_sync <= {frame_err_tgl_sync[1:0], frame_err_tgl};
end
assign sts_frame_err_set = frame_err_tgl_sync[2] ^ frame_err_tgl_sync[1];

// ------------------------------------------------------------------
// Control/status interface select (CTRL_INTERFACE). Both port sets are always
// declared; IP-XACT conditional presence hides the inactive set in IP Integrator.
// ------------------------------------------------------------------
localparam integer CTRL_IF_CSR      = 0;
localparam integer CTRL_IF_DISCRETE = 1;

generate
if (CTRL_INTERFACE == CTRL_IF_DISCRETE) begin : g_discrete
    assign ctrl_realign_pulse = ctrl_realign;
    assign ctrl_stream_enable = ctrl_stream_en;
    // No tap override in discrete mode (TAP_CTRL is CSR-only).
    assign ctrl_ovr_en  = 1'b0;
    assign ctrl_ovr_tap = 9'd0;
    // TRACK_CTRL is CSR-only: ALIGN_MODE fixes the mode, with the TRACK_CTRL
    // reset settings (deadband 2, offset 0, interval 191, about 100 ms on the -14).
    assign ctrl_trk_en       = ALIGN_CONTINUAL;
    assign ctrl_trk_deadband = 4'd2;
    assign ctrl_trk_offset   = 8'd0;
    assign ctrl_trk_interval = 16'd191;

    // No LTC register access in discrete mode; the LTC stays at power-on defaults.
    assign spi_reconfig = 1'b0;
    assign reg_we       = 1'b0;
    assign reg_waddr    = 7'd0;
    assign reg_wdata    = 8'd0;
    assign reg_rreq     = 1'b0;
    assign reg_raddr    = 7'd0;

    assign adc_ready        = sts_adc_ready;
    assign capture_clk_alive = sts_capture_clk_alive;
    assign align_done        = sts_align_done;
    assign align_fail        = sts_align_fail;
    assign align_phase       = sts_align_phase;
    assign eye_width         = sts_eye_width;

    // Sticky fault flags, same semantics as CSR STATUS[4] / STATUS[7].
    reg ovf_sticky_pin;
    always @(posedge aclk) begin
        if (!aresetn)              ovf_sticky_pin <= 1'b0;
        else if (sts_overflow_set) ovf_sticky_pin <= 1'b1;
        else if (ctrl_clear_flags) ovf_sticky_pin <= 1'b0;
    end
    assign fifo_overflow = ovf_sticky_pin;

    reg frame_err_sticky_pin;
    always @(posedge aclk) begin
        if (!aresetn)               frame_err_sticky_pin <= 1'b0;
        else if (sts_frame_err_set) frame_err_sticky_pin <= 1'b1;
        else if (ctrl_clear_flags)  frame_err_sticky_pin <= 1'b0;
    end
    assign frame_error = frame_err_sticky_pin;

    assign s_axi_awready = 1'b0;
    assign s_axi_wready  = 1'b0;
    assign s_axi_bresp   = 2'b00;
    assign s_axi_bvalid  = 1'b0;
    assign s_axi_arready = 1'b0;
    assign s_axi_rdata   = 32'd0;
    assign s_axi_rresp   = 2'b00;
    assign s_axi_rvalid  = 1'b0;
end else begin : g_csr
    syzygy_adc_csr #(
        .TRACK_EN_RESET (ALIGN_CONTINUAL)
    ) adc_csr_impl (
        .s_axi_aclk     (aclk),
        .s_axi_aresetn  (aresetn),
        .s_axi_awaddr   (s_axi_awaddr),
        .s_axi_awvalid  (s_axi_awvalid),
        .s_axi_awready  (s_axi_awready),
        .s_axi_wdata    (s_axi_wdata),
        .s_axi_wvalid   (s_axi_wvalid),
        .s_axi_wready   (s_axi_wready),
        .s_axi_bresp    (s_axi_bresp),
        .s_axi_bvalid   (s_axi_bvalid),
        .s_axi_bready   (s_axi_bready),
        .s_axi_araddr   (s_axi_araddr),
        .s_axi_arvalid  (s_axi_arvalid),
        .s_axi_arready  (s_axi_arready),
        .s_axi_rdata    (s_axi_rdata),
        .s_axi_rresp    (s_axi_rresp),
        .s_axi_rvalid   (s_axi_rvalid),
        .s_axi_rready   (s_axi_rready),

        .ctrl_realign_pulse (ctrl_realign_pulse),
        .ctrl_stream_enable (ctrl_stream_enable),
        .ctrl_spi_reconfig  (spi_reconfig),
        .ctrl_ovr_en        (ctrl_ovr_en),
        .ctrl_ovr_tap       (ctrl_ovr_tap),
        .ctrl_trk_en        (ctrl_trk_en),
        .ctrl_trk_deadband  (ctrl_trk_deadband),
        .ctrl_trk_offset    (ctrl_trk_offset),
        .ctrl_trk_interval  (ctrl_trk_interval),

        .reg_waddr        (reg_waddr),
        .reg_wdata        (reg_wdata),
        .reg_we           (reg_we),
        .reg_raddr        (reg_raddr),
        .reg_rreq         (reg_rreq),
        .reg_rdata        (reg_rdata),
        .reg_rerr         (reg_rerr),
        .reg_rvalid       (reg_rvalid),

        .sts_adc_ready         (sts_adc_ready),
        .sts_capture_clk_alive (sts_capture_clk_alive),
        .sts_align_done        (sts_align_done),
        .sts_align_fail        (sts_align_fail),
        .sts_overflow_set      (sts_overflow_set),
        .sts_frame_err_set     (sts_frame_err_set),
        .sts_align_phase       (sts_align_phase),
        .sts_eye_width         (sts_eye_width),
        .sts_live_tap          (sts_live_tap),
        .sts_data_tap          (sts_data_tap),
        .sts_trk_busy          (sts_trk_busy),
        .sts_trk_count         (sts_trk_count),
        .sts_trk_last_move     (sts_trk_last_move),
        .sts_trk_err_count     (sts_trk_err_count),
        .sts_trk_left          (sts_trk_left),
        .sts_trk_right         (sts_trk_right),
        .sts_eye_map           (sts_eye_map),
        .sts_spi_ready         (adc_spi_ready),
        .sts_spi_busy          (spi_busy),
        .sts_ovr_active        (sts_ovr_active)
    );

    assign adc_ready        = 1'b0;
    assign capture_clk_alive = 1'b0;
    assign align_done        = 1'b0;
    assign align_fail        = 1'b0;
    assign fifo_overflow     = 1'b0;
    assign frame_error       = 1'b0;
    assign align_phase       = 16'd0;
    assign eye_width         = 16'd0;
end
endgenerate

endmodule
`default_nettype wire

`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-adc-csr.v
//
// AXI4-Lite control/status register block for the SYZYGY ADC IP.
//
// Single-outstanding, 32-bit, word-aligned AXI4-Lite subordinate:
//
//   0x00 CTRL   (RW) [0]  re-align/reset      (write-1-pulse)
//                    [2]  stream_enable
//                    [8]  clear_flags         (write-1-pulse)
//                    [9]  spi_reconfig        (write-1-pulse; re-apply LTC config)
//   0x04 STATUS (RO) [0]  adc_ready
//                    [1]  capture_clk_alive
//                    [2]  align_done
//                    [3]  align_fail
//                    [4]  fifo_overflow       (sticky; cleared by clear_flags)
//                    [5]  adc_spi_ready       (SPI bring-up flush complete)
//                    [6]  spi_busy            (SPI engine/sequencer active)
//                    [7]  frame_error         (sticky; cleared by clear_flags)
//                    [8]  override_active     (tap override engaged or walking back)
//                    [9]  track_busy          (tracker probing the frame lane)
//                    [10] align_mode_reset    (constant: ALIGN_MODE, the reset
//                                              value of TRACK_CTRL[0])
//   0x08 ALIGN  (RO) [15:0]  align_phase
//                    [31:16] eye_width
//                    Latest tracked center / width once tracking has run.
//   0x0C TAP    (RO) [8:0]   live_tap: the tap the frame-lane IDELAYE3 holds
//                            (CNTVALUEOUT)
//                    [24:16] data_tap: the tap the data lanes hold. Equal to
//                            [8:0] except while the tracker probes.
//   0x10 TAP_CTRL (RW) [8:0]  override_tap
//                    [16]    override_en: after a successful sweep, walk both
//                            taps to override_tap (<= 8 taps per load) and hold;
//                            clear to walk back. adc_ready stays high. Ignored
//                            after a failed sweep.
//   0x14 TRACK_CTRL (RW) [0]     track_en: 0 = one-shot, 1 = continual
//                            (reset = TRACK_EN_RESET, from ALIGN_MODE)
//                    [7:4]   deadband: taps the data tap may sit off target (2)
//                    [15:8]  offset, signed: data target = center + offset (0)
//                    [31:16] interval, units of 65536 adc_data_clk cycles
//                            (191 = ~100 ms on the -14)
//   0x18 TRACK_STAT (RO) [15:0] completed cycles, [23:16] last data move
//                            (signed taps), [31:24] abandoned cycles (saturating)
//   0x1C TRACK_EDGES (RO) [8:0] last first-bad tap below center,
//                            [24:16] last first-bad tap above center
//   0x40 + 4*N  LTC register N  (RW)  N = 0..NUM_REGS-1
//                    LTC2264/LTC2268 map: 0x00 RESET, 0x01 POWER-DOWN,
//                    0x02 TIMING, 0x03 OUTPUT-MODE, 0x04 FORMAT. A write
//                    pushes the low byte to the LTC over SPI. A read is live
//                    off the silicon and stalls the AXI read channel until the
//                    SPI transaction completes (SLVERR on watchdog timeout).
//   0x80 + 4*N  EYE_MAP word N (RO), N = 0..15: bit k = tap 32*N + k was good
//                    in the last sweep. Valid while align_done or align_fail.
//
// No WSTRB: every write is a full 32-bit word, so write-1-pulse bits fire on the
// data bit alone.
//
//------------------------------------------------------------------------
// Copyright (c) 2024-2026 Opal Kelly Incorporated
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

module syzygy_adc_csr #(
    parameter integer C_S_AXI_ADDR_WIDTH = 12,
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // Reset value of TRACK_CTRL[0] (0 = one-shot, 1 = continual alignment);
    // also read back as STATUS[10].
    parameter integer TRACK_EN_RESET     = 0
)(
    // AXI4-Lite subordinate (s_axi_aclk domain)
    input  wire                              s_axi_aclk,
    input  wire                              s_axi_aresetn,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire                              s_axi_awvalid,
    output wire                              s_axi_awready,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire                              s_axi_wvalid,
    output wire                              s_axi_wready,
    output wire [1:0]                        s_axi_bresp,
    output wire                              s_axi_bvalid,
    input  wire                              s_axi_bready,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire                              s_axi_arvalid,
    output wire                              s_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_rdata,
    output wire [1:0]                        s_axi_rresp,
    output wire                              s_axi_rvalid,
    input  wire                              s_axi_rready,

    // Control outputs (s_axi_aclk domain)
    output wire        ctrl_realign_pulse,   // CTRL[0] write-1-pulse
    output wire        ctrl_stream_enable,   // CTRL[2]
    output wire        ctrl_spi_reconfig,    // CTRL[9] write-1-pulse
    output wire        ctrl_ovr_en,          // TAP_CTRL[16] (level)
    output wire [8:0]  ctrl_ovr_tap,         // TAP_CTRL[8:0] (level)
    output wire        ctrl_trk_en,          // TRACK_CTRL (levels)
    output wire [3:0]  ctrl_trk_deadband,
    output wire [7:0]  ctrl_trk_offset,
    output wire [15:0] ctrl_trk_interval,

    // Raw device-register write port (to syzygy_adc_spi_ctrl)
    output wire [6:0]  reg_waddr,
    output wire [7:0]  reg_wdata,
    output wire        reg_we,               // 1-cycle strobe

    // Live device-register read port (to/from syzygy_adc_spi_ctrl)
    output reg  [6:0]  reg_raddr,
    output reg         reg_rreq,             // held until reg_rvalid
    input  wire [7:0]  reg_rdata,
    input  wire        reg_rerr,
    input  wire        reg_rvalid,

    // Status inputs (already synchronized to s_axi_aclk by the top level)
    input  wire        sts_adc_ready,
    input  wire        sts_capture_clk_alive,
    input  wire        sts_align_done,
    input  wire        sts_align_fail,
    input  wire        sts_overflow_set,     // 1-cycle set pulse, this domain
    input  wire        sts_frame_err_set,    // 1-cycle set pulse, this domain
    input  wire [15:0] sts_align_phase,
    input  wire [15:0] sts_eye_width,
    input  wire [8:0]   sts_live_tap,     // TAP[8:0]   (already synchronized)
    input  wire [8:0]   sts_data_tap,     // TAP[24:16] (already synchronized)
    input  wire         sts_trk_busy,     // STATUS[9]
    input  wire [15:0]  sts_trk_count,    // TRACK_STAT
    input  wire [7:0]   sts_trk_last_move,
    input  wire [7:0]   sts_trk_err_count,
    input  wire [8:0]   sts_trk_left,     // TRACK_EDGES
    input  wire [8:0]   sts_trk_right,
    input  wire [511:0] sts_eye_map,      // EYE_MAP
    input  wire        sts_spi_ready,        // STATUS[5]
    input  wire        sts_spi_busy,         // STATUS[6]
    input  wire        sts_ovr_active        // STATUS[8] (already synchronized)
);

// addr[7:2] selects one of 64 words. NUM_REGS must match syzygy_adc_spi_ctrl.
localparam integer NUM_REGS = 8;
localparam [5:0] W_CTRL     = 6'd0,
                 W_STATUS   = 6'd1,
                 W_ALIGN    = 6'd2,
                 W_TAP      = 6'd3,
                 W_TAP_CTRL = 6'd4,    // 0x10
                 W_TRK_CTRL = 6'd5,    // 0x14
                 W_TRK_STAT = 6'd6,    // 0x18
                 W_TRK_EDGE = 6'd7,    // 0x1C
                 W_RAW_BASE = 6'd16,   // 0x40
                 W_EYE_BASE = 6'd32,   // 0x80
                 W_EYE_END  = 6'd47;   // 0xBC
localparam [5:0] W_RAW_END  = W_RAW_BASE + NUM_REGS - 1;

// Address bits above the word decode must be zero for an access to be mapped, or
// the 4 KB block aliases every 256 bytes. Requires C_S_AXI_ADDR_WIDTH > 8.
localparam integer HI_WIDTH = C_S_AXI_ADDR_WIDTH - 8;

localparam [1:0] RESP_OKAY   = 2'b00,
                 RESP_SLVERR = 2'b10,
                 RESP_DECERR = 2'b11;

// ------------------------------------------------------------------
// Write channel (canonical single-outstanding AXI4-Lite subordinate)
// ------------------------------------------------------------------
reg                          axi_awready;
reg                          axi_wready;
reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
reg                          axi_bvalid;
reg                          aw_en;

assign s_axi_awready = axi_awready;
assign s_axi_wready  = axi_wready;
assign s_axi_bvalid  = axi_bvalid;

wire wr_latch = ~axi_awready & s_axi_awvalid & s_axi_wvalid & aw_en;

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        axi_awready <= 1'b0;
        axi_wready  <= 1'b0;
        axi_awaddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        axi_bvalid  <= 1'b0;
        aw_en       <= 1'b1;
    end else begin
        // Address/data accept: assert ready for one cycle, latch address.
        if (wr_latch) begin
            axi_awready <= 1'b1;
            axi_wready  <= 1'b1;
            axi_awaddr  <= s_axi_awaddr;
            aw_en       <= 1'b0;
        end else begin
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            if (s_axi_bready & axi_bvalid)
                aw_en <= 1'b1;
        end

        // Write response.
        if (axi_awready & s_axi_awvalid & axi_wready & s_axi_wvalid & ~axi_bvalid)
            axi_bvalid <= 1'b1;
        else if (s_axi_bready & axi_bvalid)
            axi_bvalid <= 1'b0;
    end
end

// Register write strobe (address + data both accepted this cycle).
wire       wren     = axi_awready & s_axi_awvalid & axi_wready & s_axi_wvalid;
wire [5:0] w_word   = axi_awaddr[7:2];
wire       w_in_map = (axi_awaddr[C_S_AXI_ADDR_WIDTH-1:8] == {HI_WIDTH{1'b0}});
wire       ctrl_sel = w_in_map && (w_word == W_CTRL);
wire       tapc_sel = w_in_map && (w_word == W_TAP_CTRL);
wire       trkc_sel = w_in_map && (w_word == W_TRK_CTRL);
wire       raw_sel  = w_in_map && (w_word >= W_RAW_BASE) && (w_word <= W_RAW_END);
wire [5:0] raw_idx  = w_word - W_RAW_BASE;   // 0..NUM_REGS-1 when raw_sel

// Writes to read-only words are accepted and ignored. Unmapped words answer
// DECERR.
wire       w_mapped = ctrl_sel | tapc_sel | trkc_sel | raw_sel |
                      (w_in_map && ((w_word == W_TRK_STAT) || (w_word == W_TRK_EDGE))) |
                      (w_in_map && ((w_word == W_STATUS) || (w_word == W_ALIGN) ||
                                    (w_word == W_TAP) ||
                                    ((w_word >= W_EYE_BASE) && (w_word <= W_EYE_END))));

reg [1:0] axi_bresp;
assign s_axi_bresp = axi_bresp;

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) axi_bresp <= RESP_OKAY;
    else if (wren)      axi_bresp <= w_mapped ? RESP_OKAY : RESP_DECERR;
end

// ------------------------------------------------------------------
// CTRL register
// ------------------------------------------------------------------
reg reg_stream_enable;

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
        reg_stream_enable <= 1'b1;   // streaming on by default
    else if (wren & ctrl_sel)
        reg_stream_enable <= s_axi_wdata[2];
end

// Write-1-pulse action bits: 1-cycle strobes.
wire ctrl_clear_flags = wren & ctrl_sel & s_axi_wdata[8];

assign ctrl_realign_pulse = wren & ctrl_sel & s_axi_wdata[0];
assign ctrl_stream_enable = reg_stream_enable;
assign ctrl_spi_reconfig  = wren & ctrl_sel & s_axi_wdata[9];

// TAP_CTRL: manual tap override request (levels)
reg       reg_ovr_en;
reg [8:0] reg_ovr_tap;
always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        reg_ovr_en  <= 1'b0;
        reg_ovr_tap <= 9'd0;
    end else if (wren & tapc_sel) begin
        reg_ovr_en  <= s_axi_wdata[16];
        reg_ovr_tap <= s_axi_wdata[8:0];
    end
end
assign ctrl_ovr_en  = reg_ovr_en;
assign ctrl_ovr_tap = reg_ovr_tap;

// TRACK_CTRL: dynamic tracking parameters (levels). Reset: TRACK_EN_RESET,
// deadband 2, offset 0, ~100 ms.
localparam [3:0]  TRK_DEADBAND_RST = 4'd2;
localparam [15:0] TRK_INTERVAL_RST = 16'd191;
reg        reg_trk_en;
reg [3:0]  reg_trk_deadband;
reg [7:0]  reg_trk_offset;
reg [15:0] reg_trk_interval;
always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        reg_trk_en       <= (TRACK_EN_RESET != 0);
        reg_trk_deadband <= TRK_DEADBAND_RST;
        reg_trk_offset   <= 8'd0;
        reg_trk_interval <= TRK_INTERVAL_RST;
    end else if (wren & trkc_sel) begin
        reg_trk_en       <= s_axi_wdata[0];
        reg_trk_deadband <= s_axi_wdata[7:4];
        reg_trk_offset   <= s_axi_wdata[15:8];
        reg_trk_interval <= s_axi_wdata[31:16];
    end
end
assign ctrl_trk_en       = reg_trk_en;
assign ctrl_trk_deadband = reg_trk_deadband;
assign ctrl_trk_offset   = reg_trk_offset;
assign ctrl_trk_interval = reg_trk_interval;

// Raw device-register write port.
assign reg_we    = wren & raw_sel;
assign reg_waddr = {1'b0, raw_idx};   // 0..NUM_REGS-1, zero-extended to 7 bits
assign reg_wdata = s_axi_wdata[7:0];

// ------------------------------------------------------------------
// Sticky fault flags. Set wins over a coincident clear.
// ------------------------------------------------------------------
reg ovf_sticky;
always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)         ovf_sticky <= 1'b0;
    else if (sts_overflow_set)  ovf_sticky <= 1'b1;
    else if (ctrl_clear_flags)  ovf_sticky <= 1'b0;
end

reg frame_err_sticky;
always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)         frame_err_sticky <= 1'b0;
    else if (sts_frame_err_set) frame_err_sticky <= 1'b1;
    else if (ctrl_clear_flags)  frame_err_sticky <= 1'b0;
end

// ------------------------------------------------------------------
// Read channel.
// ------------------------------------------------------------------
localparam integer         RD_WDOG_W   = 20;   // ~10 ms at 100 MHz
localparam [RD_WDOG_W-1:0] RD_WDOG_MAX = {RD_WDOG_W{1'b1}};
reg                          axi_arready;
reg                          axi_rvalid;
reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
reg [1:0]                    axi_rresp;
reg                          r_wait;    // waiting on a live device read
reg [RD_WDOG_W-1:0]          r_wdog;    // bounds that wait

assign s_axi_arready = axi_arready;
assign s_axi_rvalid  = axi_rvalid;
assign s_axi_rdata   = axi_rdata;
assign s_axi_rresp   = axi_rresp;

wire [5:0] ar_word   = s_axi_araddr[7:2];
wire       ar_in_map = (s_axi_araddr[C_S_AXI_ADDR_WIDTH-1:8] == {HI_WIDTH{1'b0}});
wire       ar_raw    = ar_in_map && (ar_word >= W_RAW_BASE) && (ar_word <= W_RAW_END);
wire [5:0] ar_idx    = ar_word - W_RAW_BASE;
wire       ar_eye    = (ar_word >= W_EYE_BASE) && (ar_word <= W_EYE_END);
wire [8:0] ar_eye_lo = {ar_word[3:0], 5'b0};   // first tap of the addressed EYE_MAP word

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        axi_arready <= 1'b0;
        axi_rvalid  <= 1'b0;
        axi_rdata   <= {C_S_AXI_DATA_WIDTH{1'b0}};
        axi_rresp   <= RESP_OKAY;
        reg_rreq    <= 1'b0;
        reg_raddr   <= 7'd0;
        r_wait      <= 1'b0;
        r_wdog      <= RD_WDOG_MAX;
    end else begin
        axi_arready <= 1'b0;

        if (!r_wait) begin
            if (~axi_arready & s_axi_arvalid & ~axi_rvalid) begin
                axi_arready <= 1'b1;   // accept the address
                if (ar_raw) begin
                    // Live device read: request it and stall RVALID.
                    reg_raddr <= {1'b0, ar_idx};
                    reg_rreq  <= 1'b1;
                    r_wait    <= 1'b1;
                    r_wdog    <= RD_WDOG_MAX;
                end else begin
                    axi_rvalid <= 1'b1;
                    axi_rresp  <= RESP_OKAY;
                    axi_rdata  <= {C_S_AXI_DATA_WIDTH{1'b0}};
                    if (!ar_in_map)
                        axi_rresp <= RESP_DECERR;
                    else case (ar_word)
                        W_CTRL:   axi_rdata <= {29'b0, reg_stream_enable, 2'b0};
                        W_STATUS: axi_rdata <= {21'b0, (TRACK_EN_RESET != 0),
                                                sts_trk_busy, sts_ovr_active, frame_err_sticky,
                                                sts_spi_busy, sts_spi_ready,
                                                ovf_sticky, sts_align_fail,
                                                sts_align_done, sts_capture_clk_alive,
                                                sts_adc_ready};
                        W_ALIGN:  axi_rdata <= {sts_eye_width, sts_align_phase};
                        W_TAP:    axi_rdata <= {7'b0, sts_data_tap, 7'b0, sts_live_tap};
                        W_TAP_CTRL: axi_rdata <= {15'b0, reg_ovr_en, 7'b0, reg_ovr_tap};
                        W_TRK_CTRL: axi_rdata <= {reg_trk_interval, reg_trk_offset,
                                                  reg_trk_deadband, 3'b0, reg_trk_en};
                        W_TRK_STAT: axi_rdata <= {sts_trk_err_count, sts_trk_last_move,
                                                  sts_trk_count};
                        W_TRK_EDGE: axi_rdata <= {7'b0, sts_trk_right, 7'b0, sts_trk_left};
                        default:  if (ar_eye) axi_rdata <= sts_eye_map[ar_eye_lo +: 32];
                                  else        axi_rresp <= RESP_DECERR;
                    endcase
                end
            end
        end else begin
            // Waiting for the controller's live-read response.
            if (reg_rvalid) begin
                reg_rreq   <= 1'b0;
                axi_rdata  <= {24'b0, reg_rdata};
                axi_rresp  <= reg_rerr ? RESP_SLVERR : RESP_OKAY;
                axi_rvalid <= 1'b1;
                r_wait     <= 1'b0;
            end
            else if (r_wdog != {RD_WDOG_W{1'b0}}) begin
                r_wdog <= r_wdog - 1'b1;
            end
            else begin
                // The controller is not going to answer. Retire the beat.
                reg_rreq   <= 1'b0;
                axi_rdata  <= {C_S_AXI_DATA_WIDTH{1'b0}};
                axi_rresp  <= RESP_SLVERR;
                axi_rvalid <= 1'b1;
                r_wait     <= 1'b0;
            end
        end

        if (axi_rvalid & s_axi_rready)
            axi_rvalid <= 1'b0;
    end
end

endmodule
`default_nettype wire

`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy_dac.v
//
// Top level wrapper for the Syzygy DAC IP.
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

module syzygy_dac #
(
    // DAC full-scale adjust defaults, per channel. Each is a 6-bit code (0..63)
    parameter integer DAC_FSADJ_I = 32,
    parameter integer DAC_FSADJ_Q = 32,

    // Sample format on dac_data_stream = AD911x TWOS bit (0x02[7]):
    //   0 = unsigned offset binary
    //   1 = signed twos complement
    parameter integer DAC_SAMPLE_FORMAT = 0,

    // Code driven on both channels from reset release until the first sample
    // arrives, once the device is in DAC_SAMPLE_FORMAT. Range 0..4095. Mid-scale
    // -- 0 V differential -- is 2048 (12'h800) unsigned, 0 (12'h000) signed.
    // The AD911x powers up unsigned regardless of DAC_SAMPLE_FORMAT, so the window
    // before the format write lands is covered by IDLE_CODE_POR instead.
    parameter integer DAC_RESET_VALUE = 2048,

    // Depth of the internal async FIFO crossing aclk -> dac_sample_clk
    parameter integer FIFO_DEPTH = 32,

    // Control/status interface select (enum):
    //   0 = AXI4-Lite CSR (dac_csr / S_AXI) -- the default register interface.
    //   1 = Discrete wires
    parameter integer CTRL_INTERFACE = 0
)
(
    // SZG-DAC Connections
    output wire [11:0] dac_data,
    output wire        dac_clk,
    output wire        dac_reset_pinmd,
    output wire        dac_sclk,
    inout  wire        dac_sdio,
    output wire        dac_cs_n,

    input wire         dac_sample_clk,

    // AXI4-Lite control/status
    // Register map: see syzygy-dac-csr.v.
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

    // Discrete control/status
    input  wire        ctrl_soft_reset,   // CTRL[0]
    input  wire        ctrl_clear_flags,  // CTRL[8]
    output wire        dac_ready,         // STATUS[0]
    output wire        fifo_underflow,    // STATUS[1]

    // AXI4-Stream subordinate on the SYSTEM clock, shared with S_AXI
    input wire  aclk,
    input wire  aresetn,

    output wire  s_axis_tready,
    input wire [31 : 0] s_axis_tdata,
    input wire  s_axis_tvalid
);

// ------------------------------------------------------------------
// Reset generation: system reset (aresetn) OR a CSR soft_reset (CTRL[0]),
// stretched so the SPI controller re-sequences, the CDC FIFO fully resets, and
// the sample-domain reset is reliably caught.
// ------------------------------------------------------------------
localparam integer RESET_STRETCH = 1024;
localparam integer RST_CNT_WIDTH = $clog2(RESET_STRETCH + 1);
reg  [RST_CNT_WIDTH-1:0] rst_cnt = RESET_STRETCH[RST_CNT_WIDTH-1:0];
wire           sys_reset = ~aresetn;   // active-high system reset (aclk)

// Core control/status nets (aclk domain). The control nets are driven by the
// CSR adapter or the discrete control pins, selected by CTRL_INTERFACE in the
// generate block below.
wire        core_soft_reset;    // soft reset request into the reset stretcher
wire        dac_ready_int;      // from the controller (aclk domain)
wire        sts_underflow_set;  // 1-cycle underflow set pulse (aclk domain)

always @(posedge aclk) begin
    if (sys_reset)            rst_cnt <= RESET_STRETCH[RST_CNT_WIDTH-1:0];
    else if (core_soft_reset) rst_cnt <= RESET_STRETCH[RST_CNT_WIDTH-1:0];   // CTRL[0]
    else if (rst_cnt != 0)    rst_cnt <= rst_cnt - 1'b1;
end

wire core_reset = sys_reset | (rst_cnt != 0);   // active-high (aclk)

// SPI control plane + controller reset (same domain as aclk).
wire spi_reset = core_reset;

// Reset synchronizer for the dac_sample_clk (DDR output) domain.
// Async assert from core_reset, sync deassert into dac_sample_clk. ASYNC_REG
// keeps the 2-FF chain packed together and flags it to the metastability-aware
// timing/placement flow (mirrors the ADC's reset_adc_sync).
(* ASYNC_REG = "TRUE" *) reg [1:0] samp_rst_sync = 2'b11;
always @(posedge dac_sample_clk or posedge core_reset) begin
    if (core_reset) samp_rst_sync <= 2'b11;
    else            samp_rst_sync <= {samp_rst_sync[0], 1'b0};
end
wire sample_reset = samp_rst_sync[1];

// SPI
wire [4:0]  spi_reg;
wire [7:0]  spi_data_in, spi_data_out;
wire        spi_send, spi_done, spi_rw;

// SPI control-plane <-> CSR nets (aclk domain). Driven by the CSR adapter in
// g_csr, or tied off in g_discrete (discrete mode does bring-up config only).
wire        spi_reconfig;      // CTRL[9] re-apply device config
wire        reg_we;            // raw device-register write strobe
wire [4:0]  reg_waddr;
wire [7:0]  reg_wdata;
wire        reg_rreq;          // live device-register read request
wire [4:0]  reg_raddr;
wire [7:0]  reg_rdata;         // live read data (controller -> CSR)
wire        reg_rerr;          // live read watchdog timeout -> SLVERR
wire        reg_rvalid;        // live read done strobe
wire        spi_busy;          // controller/engine active -> STATUS[6]
wire        spi_err_set;       // 1-cycle: a register write was dropped -> STATUS[7]
wire        fmt_applied;       // sticky: AD911x Data Control (0x02) write has landed

// AXI-Stream subordinate + clock-crossing buffer. 
wire [23:0] dac_iq;                 // {I[23:12], Q[11:0]}
wire        underflow_strobe;

// Synchronize fmt_applied (aclk, sticky level) into the sample domain. Single-bit
// level crossing that toggles at most once per reset; the false path is declared
// in xdc/syzygy_dac_cdc.xdc.
(* ASYNC_REG = "TRUE" *) reg [1:0] fmt_sync = 2'b00;
always @(posedge dac_sample_clk) begin
    if (sample_reset) fmt_sync <= 2'b00;
    else              fmt_sync <= {fmt_sync[0], fmt_applied};
end

syzygy_dac_axi_stream #(
    .FIFO_DEPTH    (FIFO_DEPTH),
    .DAC_IDLE_CODE (DAC_RESET_VALUE[11:0])
) dac_axi_stream_impl (
    .s_axis_aclk      (aclk),
    .core_reset       (core_reset),
    .s_axis_tready    (s_axis_tready),
    .s_axis_tdata     (s_axis_tdata),
    .s_axis_tvalid    (s_axis_tvalid),

    .dac_sample_clk   (dac_sample_clk),
    .sample_reset     (sample_reset),
    .fmt_applied      (fmt_sync[1]),
    .sample           (dac_iq),
    .underflow_strobe (underflow_strobe)
);

// ------------------------------------------------------------------
// Toggle-sync the sample-domain underflow_strobe into the aclk/CSR domain and
// edge-detect to a single-cycle set pulse for the CSR sticky (STATUS[1]).
// ------------------------------------------------------------------
reg uflo_tgl = 1'b0;
always @(posedge dac_sample_clk) begin
    if (underflow_strobe) uflo_tgl <= ~uflo_tgl;
end
(* ASYNC_REG = "TRUE" *) reg [2:0] uflo_sync = 3'd0;
always @(posedge aclk) begin
    uflo_sync <= {uflo_sync[1:0], uflo_tgl};
end
assign sts_underflow_set = uflo_sync[2] ^ uflo_sync[1];

syzygy_dac_phy dac_phy_impl(
    .clk      (dac_sample_clk),
    .reset    (sample_reset),

    .data_i   (dac_iq[23:12]),   // channel I (from s_axis_tdata[31:20])
    .data_q   (dac_iq[11:0]),    // channel Q (from s_axis_tdata[15:4])

    .dac_data (dac_data),
    .dac_clk  (dac_clk)   // forwarded sample clock (source-synchronous w/ data)
);

// SPI clock divider. SCLK = aclk / (2 * (SCLK_DIV + 1)) = aclk / 202.
localparam integer SCLK_DIV = 100;

syzygy_dac_spi #(
    .SCLK_DIV     (SCLK_DIV)
) dac_spi(
    .clk          (aclk),
    .reset        (spi_reset),

    .dac_sclk        (dac_sclk),         // DAC SPI clock pad
    .dac_sdio        (dac_sdio),         // DAC SPI SDIO pad (bidirectional)
    .dac_cs_n        (dac_cs_n),         // DAC chip select pad (active low)
    .dac_reset_pinmd (dac_reset_pinmd),  // DAC reset / pin-mode pad

    .spi_reg      (spi_reg),      // DAC SPI register address
    .spi_data_in  (spi_data_in),  // Data to DAC
    .spi_data_out (spi_data_out), // Data from DAC (live register reads)
    .spi_send     (spi_send),     // Send command
    .spi_done     (spi_done),     // Command is complete, data_out valid
    .spi_rw       (spi_rw)        // Read or write
);

syzygy_dac_spi_ctrl #(
    .DAC_FSADJ_I_DEFAULT (DAC_FSADJ_I),
    .DAC_FSADJ_Q_DEFAULT (DAC_FSADJ_Q),
    .DAC_SAMPLE_FORMAT   (DAC_SAMPLE_FORMAT)
) dac_control(
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

    .fmt_applied (fmt_applied),
    .spi_ready   (dac_ready_int),  // already in the aclk domain -> STATUS[0]
    .spi_busy    (spi_busy),
    .spi_err_set (spi_err_set),

    .spi_reg     (spi_reg),
    .spi_data_in (spi_data_in),
    .spi_send    (spi_send),
    .spi_done    (spi_done),
    .spi_data_out(spi_data_out),
    .spi_rw      (spi_rw)
);

// ------------------------------------------------------------------
// Control/status interface select for IPI integrator (CTRL_INTERFACE)
//
//   0 = AXI4-Lite CSR (dac_csr / S_AXI)
//   1 = Discrete wires
//
// ------------------------------------------------------------------
localparam integer CTRL_IF_CSR      = 0;
localparam integer CTRL_IF_DISCRETE = 1;

generate
if (CTRL_INTERFACE == CTRL_IF_DISCRETE) begin : g_discrete
    // ---- Discrete control/status pins ----
    assign core_soft_reset = ctrl_soft_reset;

    assign spi_reconfig = 1'b0;
    assign reg_we       = 1'b0;
    assign reg_waddr    = 5'd0;
    assign reg_wdata    = 8'd0;
    assign reg_rreq     = 1'b0;
    assign reg_raddr    = 5'd0;

    assign dac_ready = dac_ready_int;

    // Sticky FIFO-underflow flag (same semantics as the CSR STATUS[1]): set by
    // the synchronized underflow pulse, cleared by the clear_flags strobe.
    reg uflo_sticky_pin;
    always @(posedge aclk) begin
        if (!aresetn)               uflo_sticky_pin <= 1'b0;
        else if (sts_underflow_set) uflo_sticky_pin <= 1'b1;
        else if (ctrl_clear_flags)  uflo_sticky_pin <= 1'b0;
    end
    assign fifo_underflow = uflo_sticky_pin;

    // S_AXI unused in this mode -- drive its outputs to benign constants so the
    // (always-declared) AXI ports are not left floating.
    assign s_axi_awready = 1'b0;
    assign s_axi_wready  = 1'b0;
    assign s_axi_bresp   = 2'b00;
    assign s_axi_bvalid  = 1'b0;
    assign s_axi_arready = 1'b0;
    assign s_axi_rdata   = 32'd0;
    assign s_axi_rresp   = 2'b00;
    assign s_axi_rvalid  = 1'b0;
end else begin : g_csr
    // ---- AXI4-Lite control/status registers (dac_csr / S_AXI, aclk domain) ----
    syzygy_dac_csr dac_csr_impl (
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

        .ctrl_soft_reset   (core_soft_reset),
        .ctrl_spi_reconfig (spi_reconfig),

        .reg_waddr         (reg_waddr),
        .reg_wdata         (reg_wdata),
        .reg_we            (reg_we),
        .reg_raddr         (reg_raddr),
        .reg_rreq          (reg_rreq),
        .reg_rdata         (reg_rdata),
        .reg_rerr          (reg_rerr),
        .reg_rvalid        (reg_rvalid),

        .sts_dac_ready     (dac_ready_int),
        .sts_spi_busy      (spi_busy),
        .sts_underflow_set (sts_underflow_set),
        .sts_spi_err_set   (spi_err_set)
    );

    // Discrete status pins are hidden in IPI for this mode -- tie them off.
    assign dac_ready      = 1'b0;
    assign fifo_underflow = 1'b0;
end
endgenerate

// User logic ends

endmodule
`default_nettype wire

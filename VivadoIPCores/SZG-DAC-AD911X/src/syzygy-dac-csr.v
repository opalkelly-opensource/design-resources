`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-dac-csr.v
//
// AXI4-Lite control/status register block for the SYZYGY DAC IP.
//
// A small, hand-written AXI4-Lite subordinate (single outstanding transaction,
// 32-bit, word-aligned) on the aclk domain -- the same domain as the SPI
// control plane and the AXIS subordinate -- so the controls it drives need no CDC.
//
// There is no WSTRB. Every write is a full 32-bit word, so the write-1-pulse bits
// fire on the data bit alone. The FrontPanel FX4 host does not source a write
// strobe on its AXI4-Lite manager, and an axi_crossbar in front of this subordinate ties
// the lanes to 4'hF on its behalf, so a per-lane qualifier could never be false.
//
//   0x00 CTRL   (RW) [0]  soft_reset     (write-1-pulse)
//                    [8]  clear_flags    (write-1-pulse)
//                    [9]  spi_reconfig   (write-1-pulse; re-apply device config)
//   0x04 STATUS (RO) [0]  dac_ready
//                    [1]  fifo_underflow (sticky; cleared by clear_flags)
//                    [5]  spi_ready      (alias of dac_ready; cross-IP parity)
//                    [6]  spi_busy
//                    [7]  spi_error      (sticky; cleared by clear_flags) -- a
//                         device-register write was dropped
//   0x08        reserved
//   0x40 + 4*N  AD911x register N  (RW)  N = 0..NUM_REGS-1
//                    Direct-mapped device registers.
//
// fifo_underflow: sts_underflow_set is a single-cycle set pulse already
// synchronized to aclk by the top level; the sticky is owned here so clear_flags
// is a same-domain clear.
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

module syzygy_dac_csr #(
    parameter integer C_S_AXI_ADDR_WIDTH    = 12,
    parameter integer C_S_AXI_DATA_WIDTH    = 32
)(
    // AXI4-Lite subordinate (aclk domain)
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

    // Control outputs (aclk domain)
    output wire        ctrl_soft_reset,      // CTRL[0] write-1-pulse
    output wire        ctrl_spi_reconfig,    // CTRL[9] write-1-pulse

    // Raw device-register write port (to syzygy_dac_spi_ctrl)
    output wire [4:0]  reg_waddr,
    output wire [7:0]  reg_wdata,
    output wire        reg_we,               // 1-cycle strobe

    // Live device-register read port (to/from syzygy_dac_spi_ctrl)
    output reg  [4:0]  reg_raddr,
    output reg         reg_rreq,             // held until reg_rvalid
    input  wire [7:0]  reg_rdata,
    input  wire        reg_rerr,
    input  wire        reg_rvalid,

    // Status inputs (aclk domain; sts_underflow_set already synchronized)
    input  wire        sts_dac_ready,
    input  wire        sts_spi_busy,
    input  wire        sts_underflow_set,    // 1-cycle set pulse, this domain
    input  wire        sts_spi_err_set       // 1-cycle set pulse: a register write
                                             // was dropped (queue full or SPI
                                             // timeout)
);

// Word address (registers are 4 bytes apart). Decode addr[7:2] -> 64 words:
//   word 0  = CTRL, 1 = STATUS  (word 2 / 0x08 reserved)
//   word 16..(16+NUM_REGS-1) = direct-mapped device registers (base 0x40)
localparam integer NUM_REGS  = 32;
localparam [5:0]   W_CTRL     = 6'd0,
                   W_STATUS   = 6'd1,
                   W_RAW_BASE = 6'd16;   // 0x40
localparam [5:0]   W_RAW_END  = W_RAW_BASE + NUM_REGS - 1;  // 0x40 + 4*31 = 0xBC

localparam [1:0] RESP_OKAY   = 2'b00,
                 RESP_SLVERR = 2'b10;

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
assign s_axi_bresp   = 2'b00;   // always OKAY (writes are buffered, never fail)

wire wr_latch = ~axi_awready & s_axi_awvalid & s_axi_wvalid & aw_en;

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        axi_awready <= 1'b0;
        axi_wready  <= 1'b0;
        axi_awaddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        axi_bvalid  <= 1'b0;
        aw_en       <= 1'b1;
    end else begin
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

        if (axi_awready & s_axi_awvalid & axi_wready & s_axi_wvalid & ~axi_bvalid)
            axi_bvalid <= 1'b1;
        else if (s_axi_bready & axi_bvalid)
            axi_bvalid <= 1'b0;
    end
end

wire       wren      = axi_awready & s_axi_awvalid & axi_wready & s_axi_wvalid;
wire [5:0] w_word    = axi_awaddr[7:2];
wire       ctrl_sel  = (w_word == W_CTRL);
wire       raw_sel   = (w_word >= W_RAW_BASE) && (w_word <= W_RAW_END);
wire [5:0] raw_idx6  = w_word - W_RAW_BASE;   // 0..NUM_REGS-1 when raw_sel

// Write-1-pulse action bits and the raw-register write port.
wire ctrl_clear_flags = wren & ctrl_sel & s_axi_wdata[8];

assign ctrl_soft_reset   = wren & ctrl_sel & s_axi_wdata[0];
assign ctrl_spi_reconfig = wren & ctrl_sel & s_axi_wdata[9];

assign reg_we    = wren & raw_sel;
assign reg_waddr = raw_idx6[4:0];
assign reg_wdata = s_axi_wdata[7:0];

// ------------------------------------------------------------------
// Sticky FIFO-underflow flag (owned in this domain so clear is same-domain).
// ------------------------------------------------------------------
reg uflo_sticky;
always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)         uflo_sticky <= 1'b0;
    else if (sts_underflow_set) uflo_sticky <= 1'b1;   // set wins over clear
    else if (ctrl_clear_flags)  uflo_sticky <= 1'b0;
end

// Sticky SPI-error flag: a device-register write was dropped, either because the
// controller's command queue was full or because its SPI transaction timed out.
// The write path is otherwise non-stalling and never returns an error over AXI
// (BRESP is always OKAY), so this is the only way a lost write is visible.
reg spierr_sticky;
always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)        spierr_sticky <= 1'b0;
    else if (sts_spi_err_set)  spierr_sticky <= 1'b1;   // set wins over clear
    else if (ctrl_clear_flags) spierr_sticky <= 1'b0;
end

// ------------------------------------------------------------------
// Read channel.
//
// Internal registers (CTRL/STATUS) answer in one cycle. A direct-mapped
// device register is served LIVE: accept the address, request an SPI read from
// the controller, hold RVALID low until reg_rvalid, then return the byte.
//
// The controller bounds that stall (see syzygy-dac-spi-ctrl.v), so reg_rvalid
// always asserts in bounded time -- but the stall is real, roughly 21 us per
// queued transfer at a 156 MHz aclk.
// ------------------------------------------------------------------
reg                          axi_arready;
reg                          axi_rvalid;
reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
reg [1:0]                    axi_rresp;
reg                          r_wait;    // waiting on a live device read

assign s_axi_arready = axi_arready;
assign s_axi_rvalid  = axi_rvalid;
assign s_axi_rdata   = axi_rdata;
assign s_axi_rresp   = axi_rresp;

wire [5:0] ar_word = s_axi_araddr[7:2];
wire       ar_raw  = (ar_word >= W_RAW_BASE) && (ar_word <= W_RAW_END);
wire [5:0] ar_idx6 = ar_word - W_RAW_BASE;

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        axi_arready <= 1'b0;
        axi_rvalid  <= 1'b0;
        axi_rdata   <= {C_S_AXI_DATA_WIDTH{1'b0}};
        axi_rresp   <= RESP_OKAY;
        reg_rreq    <= 1'b0;
        reg_raddr   <= 5'd0;
        r_wait      <= 1'b0;
    end else begin
        axi_arready <= 1'b0;

        if (!r_wait) begin
            if (~axi_arready & s_axi_arvalid & ~axi_rvalid) begin
                axi_arready <= 1'b1;   // accept the address
                if (ar_raw) begin
                    // Live device read: request it and stall RVALID.
                    reg_raddr <= ar_idx6[4:0];
                    reg_rreq  <= 1'b1;
                    r_wait    <= 1'b1;
                end else begin
                    axi_rvalid <= 1'b1;
                    axi_rresp  <= RESP_OKAY;
                    case (ar_word)
                        W_CTRL:   axi_rdata <= 32'b0;
                        W_STATUS: axi_rdata <= {24'b0, spierr_sticky, sts_spi_busy,
                                                sts_dac_ready, 3'b0, uflo_sticky,
                                                sts_dac_ready};
                        default:  axi_rdata <= 32'b0;   // 0x08 reserved; unmapped -> 0
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
        end

        if (axi_rvalid & s_axi_rready)
            axi_rvalid <= 1'b0;
    end
end

endmodule
`default_nettype wire

`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-dac-spi-ctrl.v
//
// SPI register controller for the SYZYGY DAC Pod (AD911x). Owns the SPI engine
// outright: it applies a bring-up config out of reset and forwards
// CSR register accesses to the device, so the full AD911x register space is
// reachable from the AXI4-Lite CSR.
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

module syzygy_dac_spi_ctrl #(
    // Depth of the write command queue, in {addr,data} entries. Power of two.
    // 32 = the whole AD911x register space, so software can rewrite every
    // register without overflowing.
    parameter integer WQ_DEPTH = 32,

    parameter integer DAC_FSADJ_I_DEFAULT = 32,
    parameter integer DAC_FSADJ_Q_DEFAULT = 32,

    parameter integer DAC_SAMPLE_FORMAT = 0,
    // SPI transaction watchdogs, in clk cycles. Generously above one framed
    // transfer (16 SCLK-divided bits) so a healthy transaction never trips them,
    // but bounded so a wedged engine cannot hang the sequencer / AXI read.
    parameter integer WR_TIMEOUT = 16384,
    parameter integer RD_TIMEOUT = 16384
)(
    input  wire        clk,
    input  wire        reset,        // active-high, synchronous (core_reset)

    input  wire        reconfig,     // 1-cycle: re-run the bring-up config

    // Raw register write port (from the CSR direct map)
    input  wire [4:0]  reg_waddr,
    input  wire [7:0]  reg_wdata,
    input  wire        reg_we,       // 1-cycle strobe

    // Live read port (from the CSR read FSM). Hold reg_rreq until reg_rvalid.
    input  wire [4:0]  reg_raddr,
    input  wire        reg_rreq,
    output reg  [7:0]  reg_rdata,
    output reg         reg_rerr,     // read watchdog timeout -> CSR returns SLVERR
    output reg         reg_rvalid,   // 1-cycle done strobe

    // Status
    output reg         fmt_applied,  // sticky: the Data Control write (0x02) has
                                     // retired, so the device is now in the
                                     // configured sample format. Used to pick the
                                     // idle code -- see syzygy-dac.v.
    output reg         spi_ready,    // sticky: initial bring-up sequence complete
    output wire        spi_busy,     // engine/sequencer active or work queued
    output wire        spi_err_set,  // 1-cycle: a write was dropped (queue full or
                                     // SPI timeout). CSR latches it sticky.

    // SPI engine handshake (syzygy_dac_spi)
    output reg  [4:0]  spi_reg,
    output reg  [7:0]  spi_data_in,
    output reg         spi_send,
    input  wire        spi_done,
    input  wire [7:0]  spi_data_out,
    output reg         spi_rw        // 0 = write, 1 = read
);

// AD911x register addresses written by the bring-up config (from the datasheet).
localparam [4:0] AD_DATACTL = 5'h02,  // Data Control (interleave / edge / clk src)
                 AD_IRSET   = 5'h04,  // I full-scale set
                 AD_IRCML   = 5'h05,  // I common-mode (internal 60 ohm)
                 AD_QRSET   = 5'h07,  // Q full-scale set
                 AD_QRCML   = 5'h08;  // Q common-mode (internal 60 ohm)

localparam TWOS_BIT = (DAC_SAMPLE_FORMAT != 0) ? 1'b1 : 1'b0;

localparam [7:0] DATA_CTRL_VALUE = {TWOS_BIT, 1'b0,    // [7] TWOS,     [6] rsvd
                                    1'b1,     1'b1,    // [5] IFIRST,   [4] IRISING
                                    1'b0,     1'b1,    // [3] SIMULBIT, [2] DCI_EN
                                    1'b0,     1'b0};   // [1] DCOSGL,   [0] DCODBL

// ------------------------------------------------------------------
// Bring-up init sequence. Fed directly into the transmit path, ahead of the
// write queue.
// ------------------------------------------------------------------
localparam integer INIT_ENTRIES = 5;

reg  [2:0] init_idx;
reg        init_done;
reg  [4:0] init_addr;
reg  [7:0] init_data;

always @* begin
    case (init_idx)
        3'd0:    begin init_addr = AD_DATACTL; init_data = DATA_CTRL_VALUE;                          end
        3'd1:    begin init_addr = AD_IRSET;   init_data = (8'h80 | {2'b00, DAC_FSADJ_I_DEFAULT[5:0]}); end
        3'd2:    begin init_addr = AD_IRCML;   init_data = 8'h80;                                    end
        3'd3:    begin init_addr = AD_QRSET;   init_data = (8'h80 | {2'b00, DAC_FSADJ_Q_DEFAULT[5:0]}); end
        default: begin init_addr = AD_QRCML;   init_data = 8'h80;                                    end
    endcase
end

// ------------------------------------------------------------------
// Write command queue: {addr[4:0], data[7:0]}. Single clock domain (everything
// here is on aclk), so a plain pointer FIFO -- no XPM, no reset-busy handshake.
// ------------------------------------------------------------------
localparam integer WQ_AW = $clog2(WQ_DEPTH);

reg  [12:0]      wq [0:WQ_DEPTH-1];
reg  [WQ_AW-1:0] wq_rd, wq_wr;
reg  [WQ_AW:0]   wq_count;

wire wq_empty = (wq_count == 0);
wire wq_full  = (wq_count == WQ_DEPTH[WQ_AW:0]);

wire [12:0] wq_dout  = wq[wq_rd];
wire [4:0]  wq_addr  = wq_dout[12:8];
wire [7:0]  wq_data  = wq_dout[7:0];

wire wq_push = reg_we & ~wq_full;
wire wq_ovf  = reg_we &  wq_full;   // dropped write

// ------------------------------------------------------------------
// Read barrier. Latched when a read is accepted: the sequencer drains queue
// entries up to this pointer (writes issued BEFORE the read, so read-after-write
// coherency holds), then issues the read. Writes pushed afterwards advance wq_wr
// past the barrier and are served after the read, so they cannot starve it.
// ------------------------------------------------------------------
reg              rd_armed;
reg [WQ_AW-1:0]  rd_barrier;
wire             rd_ready = rd_armed && (wq_rd == rd_barrier);

localparam [2:0] S_IDLE     = 3'd0,
                 S_WR_ISSUE = 3'd1,
                 S_WR_WAIT  = 3'd2,
                 S_RD_ISSUE = 3'd3,
                 S_RD_WAIT  = 3'd4;
reg [2:0]  state;
reg [15:0] wdog;
reg        wr_from_init;   // source of the transfer in flight

// A write transfer retires this cycle, either completed or timed out.
wire wr_ok      = (state == S_WR_WAIT) &&  (spi_done && !spi_send);
wire wr_timeout = (state == S_WR_WAIT) && !(spi_done && !spi_send) && (wdog == 16'd0);
wire wr_retire  = wr_ok | wr_timeout;
wire wq_pop     = wr_retire & ~wr_from_init;

// Queue overflow or a wedged engine: the write is lost, so report it.
assign spi_err_set = wr_timeout | wq_ovf;

assign spi_busy = (state != S_IDLE) | ~init_done | ~wq_empty | rd_armed;

// ------------------------------------------------------------------
// Queue pointers / occupancy.
// ------------------------------------------------------------------
always @(posedge clk) begin
    if (reset) begin
        wq_rd    <= {WQ_AW{1'b0}};
        wq_wr    <= {WQ_AW{1'b0}};
        wq_count <= {(WQ_AW+1){1'b0}};
    end else begin
        if (wq_push) begin
            wq[wq_wr] <= {reg_waddr, reg_wdata};
            wq_wr     <= wq_wr + 1'b1;
        end
        if (wq_pop)
            wq_rd <= wq_rd + 1'b1;

        case ({wq_push, wq_pop})
            2'b10:   wq_count <= wq_count + 1'b1;
            2'b01:   wq_count <= wq_count - 1'b1;
            default: ;   // idle, or simultaneous push+pop -> unchanged
        endcase
    end
end

// ------------------------------------------------------------------
// Read arming. reg_rreq is held by the CSR until reg_rvalid; the !reg_rvalid
// guard stops the trailing cycle of a completed read from re-arming the next one.
// ------------------------------------------------------------------
always @(posedge clk) begin
    if (reset) begin
        rd_armed   <= 1'b0;
        rd_barrier <= {WQ_AW{1'b0}};
    end else if (reg_rvalid) begin
        rd_armed   <= 1'b0;
    end else if (!rd_armed && reg_rreq) begin
        rd_armed   <= 1'b1;
        rd_barrier <= wq_wr;   // everything queued so far must drain first
    end
end

// ------------------------------------------------------------------
// Sequencer.
// ------------------------------------------------------------------
always @(posedge clk) begin
    if (reset) begin
        state        <= S_IDLE;
        spi_send     <= 1'b0;
        spi_rw       <= 1'b0;
        spi_reg      <= 5'd0;
        spi_data_in  <= 8'd0;
        reg_rvalid   <= 1'b0;
        reg_rerr     <= 1'b0;
        reg_rdata    <= 8'd0;
        spi_ready    <= 1'b0;
        wdog         <= 16'd0;
        wr_from_init <= 1'b0;
        init_idx     <= 3'd0;
        init_done    <= 1'b0;
        // Cleared only by reset, which also pulses RESET/PINMD and returns the
        // device to its power-on format -- so the flag tracks "device is in the
        // configured format" exactly. 'reconfig' does not reset the device.
        fmt_applied  <= 1'b0;
    end else begin
        spi_send   <= 1'b0;   // pulsed for one cycle in the *_ISSUE states
        reg_rvalid <= 1'b0;

        case (state)
        // Idle: bring-up first, then any queue entries the pending read must see
        // (read-after-write), then the read, then remaining queue entries.
        S_IDLE: begin
            if (!init_done)
                state <= S_WR_ISSUE;
            else if (rd_ready)
                state <= S_RD_ISSUE;
            else if (!wq_empty)
                state <= S_WR_ISSUE;
            else
                spi_ready <= 1'b1;   // sticky (only cleared by reset)
        end

        // Issue an SPI WRITE, from the init sequence or the queue.
        S_WR_ISSUE: begin
            if (!init_done) begin
                spi_reg      <= init_addr;
                spi_data_in  <= init_data;
                wr_from_init <= 1'b1;
            end else begin
                spi_reg      <= wq_addr;
                spi_data_in  <= wq_data;
                wr_from_init <= 1'b0;
            end
            spi_rw   <= 1'b0;
            spi_send <= 1'b1;
            wdog     <= WR_TIMEOUT[15:0];
            state    <= S_WR_WAIT;
        end

        // Wait for the engine
        S_WR_WAIT: begin
            if (wr_retire) begin
                state <= S_IDLE;
                if (wr_from_init) begin
                    // Entry 0 is the Data Control write, so once it retires the
                    // device is in the configured sample format and the idle code
                    // can switch. Note this is much earlier than spi_ready, which
                    // waits for all five entries.
                    if (init_idx == 3'd0) fmt_applied <= 1'b1;

                    if (init_idx == INIT_ENTRIES-1) init_done <= 1'b1;
                    else                            init_idx  <= init_idx + 1'b1;
                end
            end else if (wdog != 16'd0) begin
                wdog <= wdog - 1'b1;
            end
        end

        // Issue an SPI READ of the requested register.
        S_RD_ISSUE: begin
            spi_reg  <= reg_raddr;
            spi_rw   <= 1'b1;
            spi_send <= 1'b1;
            wdog     <= RD_TIMEOUT[15:0];
            state    <= S_RD_WAIT;
        end

        S_RD_WAIT: begin
            if (spi_done && !spi_send) begin
                reg_rdata  <= spi_data_out;
                reg_rerr   <= 1'b0;
                reg_rvalid <= 1'b1;
                state      <= S_IDLE;
            end else if (wdog != 16'd0) begin
                wdog <= wdog - 1'b1;
            end else begin
                reg_rdata  <= 8'hFF;
                reg_rerr   <= 1'b1;    // timeout -> CSR returns SLVERR
                reg_rvalid <= 1'b1;
                state      <= S_IDLE;
            end
        end

        default: state <= S_IDLE;
        endcase

        // Reconfig strobe: re-run the bring-up sequence. Placed after the FSM so
        // it wins over an init_idx advance retiring in the same cycle.
        if (reconfig) begin
            init_idx  <= 3'd0;
            init_done <= 1'b0;
        end
    end
end

endmodule
`default_nettype wire

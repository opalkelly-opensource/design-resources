`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-adc-spi-ctrl.v
//
// SPI register controller for the SYZYGY ADC Pod (LTC2264 / LTC2268): a shadow
// register file, flush sequencer and live-read engine behind the CSR.
//
//   * Out of reset nothing is dirty, so the LTC keeps its power-on defaults and
//     spi_ready asserts as soon as the engine is idle.
//   * A CSR write latches a shadow, sets its dirty and configured bits; the
//     sequencer drains dirty shadows to the device in the background.
//   * A CSR read is live: the FSM drains pending writes, issues one SPI read,
//     and returns the byte. On watchdog timeout reg_rerr is set.
//   * reconfig re-dirties every configured register. Unwritten registers are
//     never touched.
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

module syzygy_adc_spi_ctrl #(
    // Number of directly-mapped LTC registers (LTC defines 0x00..0x04). Power
    // of two, <= 128.
    parameter integer NUM_REGS   = 8,
    // SPI transaction watchdogs, in clk cycles. Must exceed one 16-bit frame
    // at the SCLK divider in use.
    parameter integer WR_TIMEOUT = 16384,
    parameter integer RD_TIMEOUT = 16384
)(
    input  wire        clk,
    input  wire        reset,        // active-high, synchronous

    input  wire        reconfig,     // 1-cycle: re-flush the configured registers

    // Raw register write port (from the CSR direct map)
    input  wire [6:0]  reg_waddr,
    input  wire [7:0]  reg_wdata,
    input  wire        reg_we,       // 1-cycle strobe

    // Live read port (from the CSR read FSM). Hold reg_rreq until reg_rvalid.
    input  wire [6:0]  reg_raddr,
    input  wire        reg_rreq,
    output reg  [7:0]  reg_rdata,
    output reg         reg_rerr,     // read watchdog timeout -> CSR returns SLVERR
    output reg         reg_rvalid,   // 1-cycle done strobe

    // Status
    output reg         spi_ready,    // sticky: initial (empty) bring-up flush complete
    output wire        spi_busy,     // engine/sequencer active

    // SPI engine handshake (syzygy_adc_spi)
    output reg  [6:0]  spi_reg,
    output reg  [7:0]  spi_data_in,
    output reg         spi_send,
    input  wire        spi_done,
    input  wire [7:0]  spi_data_out,
    output reg         spi_rw        // 0 = write, 1 = read
);

// Index width for a NUM_REGS-entry file (>= 1 so a 1-register file still works).
localparam integer IDX_W = (NUM_REGS > 1) ? $clog2(NUM_REGS) : 1;

// Shadow register file + dirty flags + a sticky "configured" mask (which
// registers software has ever written -- the set reconfig re-flushes).
reg  [7:0]          shadow [0:NUM_REGS-1];
reg  [NUM_REGS-1:0] dirty;
reg  [NUM_REGS-1:0] configured;

// Lowest-set-bit priority encoder over dirty[]: the next register to flush.
integer i;
reg [IDX_W-1:0] wr_idx;
reg             wr_val;
always @* begin
    wr_idx = {IDX_W{1'b0}};
    wr_val = 1'b0;
    for (i = NUM_REGS-1; i >= 0; i = i - 1)
        if (dirty[i]) begin
            wr_idx = i[IDX_W-1:0];
            wr_val = 1'b1;
        end
end

localparam [2:0] S_IDLE     = 3'd0,
                 S_WR_ISSUE = 3'd1,
                 S_WR_WAIT  = 3'd2,
                 S_RD_ISSUE = 3'd3,
                 S_RD_WAIT  = 3'd4;
reg [2:0]  state;
reg [15:0] wdog;

integer j;

assign spi_busy = (state != S_IDLE) | wr_val | reg_rreq;

always @(posedge clk) begin
    if (reset) begin
        state       <= S_IDLE;
        spi_send    <= 1'b0;
        spi_rw      <= 1'b0;
        spi_reg     <= 7'd0;
        spi_data_in <= 8'd0;
        reg_rvalid  <= 1'b0;
        reg_rerr    <= 1'b0;
        reg_rdata   <= 8'd0;
        spi_ready   <= 1'b0;
        wdog        <= 16'd0;

        dirty      <= {NUM_REGS{1'b0}};
        configured  <= {NUM_REGS{1'b0}};
        for (j = 0; j < NUM_REGS; j = j + 1)
            shadow[j] <= 8'h00;
    end else begin
        spi_send   <= 1'b0;   // pulsed for one cycle in the *_ISSUE states
        reg_rvalid <= 1'b0;

        case (state)
        // Idle: drain writes first (read-after-write coherency), then serve a
        // pending read. With nothing pending, latch the sticky ready flag.
        S_IDLE: begin
            if (wr_val || reg_we)
                // Drain all writes first (incl. one arriving this cycle) so a
                // live read always reflects post-write silicon state.
                state <= S_WR_ISSUE;
            else if (reg_rreq && !reg_rvalid)
                // Start a read only on a held request that is NOT the trailing
                // cycle of the one we just completed (reg_rreq lingers one cycle
                // until the CSR observes reg_rvalid and drops it).
                state <= S_RD_ISSUE;
            else
                spi_ready <= 1'b1;   // sticky (only cleared by reset)
        end

        // Issue an SPI WRITE of the lowest dirty register.
        S_WR_ISSUE: begin
            spi_reg       <= {{(7-IDX_W){1'b0}}, wr_idx};
            spi_data_in   <= shadow[wr_idx];
            spi_rw        <= 1'b0;
            spi_send      <= 1'b1;
            dirty[wr_idx] <= 1'b0;    // consume; a same-cycle CSR write re-sets it below
            wdog          <= WR_TIMEOUT[15:0];
            state         <= S_WR_WAIT;
        end

        // Wait for the engine (guard on !spi_send so we do not sample the pre-start
        // spi_done=1). Watchdog just drops the write and moves on.
        S_WR_WAIT: begin
            if (spi_done && !spi_send)
                state <= S_IDLE;
            else if (wdog != 16'd0)
                wdog <= wdog - 1'b1;
            else
                state <= S_IDLE;
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

        // Shadow updates must stay after the FSM so a CSR write to the register
        // being flushed this cycle re-sets its dirty bit.
        if (reg_we && (reg_waddr < NUM_REGS)) begin
            shadow[reg_waddr[IDX_W-1:0]]     <= reg_wdata;
            dirty[reg_waddr[IDX_W-1:0]]      <= 1'b1;
            configured[reg_waddr[IDX_W-1:0]] <= 1'b1;
        end

        if (reconfig)
            dirty <= dirty | configured;
    end
end

endmodule
`default_nettype wire

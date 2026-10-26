`timescale 1ns / 1ps

//------------------------------------------------------------------------
// idelay_align.v
//
// IDELAYE3 tap eye-centering FSM, with manual tap override and dynamic eye
// tracking.
//
// Two delay-line control buses:
//   data_*  -> the IDELAYE3 of every data lane (shared tap)
//   frame_* -> the IDELAYE3 of the frame lane
// Bring-up, park and override move both lines together. Tracking moves the
// frame line on its own to measure the eye and only nudges the data line.
//
// Bring-up (one-shot, after the capture pipeline is live):
//   1. For tap = 0 .. SWEEP_TAPS-1: load the tap into both lines (CNTVALUEIN +
//      LOAD pulse), dwell to let the delay + pipeline settle, then sample data_ok
//      (= frame_ok) over a window. A tap is "good" only if data_ok held high the
//      entire window.
//   2. Find the widest contiguous run of good taps. The sweep is linear: the
//      IDELAY line saturates at 0 and max, so an eye never wraps.
//   3. WALK both lines to the center tap in steps of at most MAX_TAP_STEP, then
//      assert align_done. If no run is wide enough, assert align_fail instead.
//
// Manual override: from S_DONE, ovr_en walks both lines to
// ovr_tap, holds them there and retargets when ovr_tap changes. Dropping ovr_en
// walks back to where the lines were and returns to S_DONE. align_done stays
// high throughout, so the capture path keeps streaming.
//
// Dynamic tracking, with the frame lane as monitor: with trk_en set, from
// S_DONE every trk_interval << TRACK_TICK_SHIFT cycles (override off):
//   1. Freeze the bitslip (bitslip_freeze) so the data lanes' word alignment
//      cannot follow the frame lane while it is probed.
//   2. Confirm the frame lane is good at the current center.
//   3. Step the FRAME tap down one tap at a time until data_ok fails: left edge.
//      Walk back, then step up until it fails: right edge.
//   4. New center = (left + right) / 2, width = right - left - 1. align_phase and
//      eye_width report these, so ALIGN follows the eye while tracking.
//   5. Return the frame tap to the new center; if the data tap is more than
//      trk_deadband from (center + trk_offset), move it toward that by at most
//      TRACK_MAX_STEP taps. Then unfreeze the bitslip.
// The data lanes never leave their eye during a cycle. A cycle is abandoned, and
// trk_err_count incremented, if the frame lane fails at the current center, an
// edge is not found before the ends of the delay line, or the measured width is
// under MIN_EYE_TAPS; the frame tap is returned and nothing else changes.
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

module idelay_align #(
    // Number of IDELAYE3 taps to sweep.
    parameter integer SWEEP_TAPS       = 512,
    // Slow-clock cycles to dwell after each tap load before sampling.
    parameter integer SETTLE_CYCLES    = 64,
    // Length, in slow-clock cycles, of the window over which data_ok must stay
    // high for a tap to count as good (sweep and tracking probes alike).
    parameter integer SAMPLE_CYCLES    = 64,
    // Minimum taps accepted as a valid eye.
    parameter integer MIN_EYE_TAPS     = 32,
    // Largest tap delta allowed in a single LOAD.
    parameter integer MAX_TAP_STEP     = 8,
    // trk_interval is in units of 2**TRACK_TICK_SHIFT clk cycles (65536 cycles =
    // 0.52 ms at the -14's 125 MHz adc_data_clk).
    parameter integer TRACK_TICK_SHIFT = 16,
    // Largest data-tap move per tracking cycle (<= MAX_TAP_STEP: one LOAD).
    parameter integer TRACK_MAX_STEP   = 4
) (
    input  wire        clk,        // slow capture clock (= adc_data_clk = IDELAYE3 CLK)
    input  wire        reset,      // synchronous, active high
    input  wire        start,      // begin alignment (capture pipeline live)
    input  wire        data_ok,    // 1 = frame lane valid at the FRAME tap (frame_ok)

    // IDELAYE3 control (VAR_LOAD / COUNT). EN_VTC is strapped Low at the instances.
    output reg  [8:0]  data_tap,   // -> every data lane
    output reg         data_load,
    output reg  [8:0]  frame_tap,  // -> frame lane
    output reg         frame_load,

    // Status
    output reg         align_done,
    output reg         align_fail,
    output reg  [15:0] align_phase, // eye center: from the sweep, then from tracking
    output reg  [15:0] eye_width,   // eye width (taps): from the sweep, then tracking

    // Per-tap result of the last sweep; tracking does not touch it.
    output wire [SWEEP_TAPS-1:0] good_map,

    // Manual tap override, quasi-static levels in this domain.
    input  wire        ovr_en,
    input  wire [8:0]  ovr_tap,
    output reg         ovr_active,

    // Dynamic tracking, quasi-static levels in this domain.
    input  wire        trk_en,
    input  wire [3:0]  trk_deadband,   // taps the data tap may sit off target
    input  wire [7:0]  trk_offset,     // signed: data target = center + offset
    input  wire [15:0] trk_interval,   // cycle period, units of 2**TRACK_TICK_SHIFT
    output reg         bitslip_freeze, // hold the data-lane word alignment
    output reg         trk_busy,       // a tracking cycle is probing the frame lane
    output reg  [15:0] trk_count,      // completed (successful) tracking cycles
    output reg  [7:0]  trk_last_move,  // signed data-tap move of the last cycle
    output reg  [7:0]  trk_err_count,  // abandoned cycles (saturating)
    output reg  [8:0]  trk_left,       // last measured first-bad tap below center
    output reg  [8:0]  trk_right       // last measured first-bad tap above center
);

localparam integer IDX_WIDTH = $clog2(SWEEP_TAPS + 1);
localparam integer TMR_WIDTH = 16 + TRACK_TICK_SHIFT;
localparam [IDX_WIDTH-1:0] TAP_MAX = SWEEP_TAPS - 1;

localparam [4:0]
    S_IDLE        = 5'd0,
    S_LOAD        = 5'd1,
    S_SETTLE      = 5'd2,
    S_SAMPLE      = 5'd3,
    S_NEXT        = 5'd4,
    S_ANALYZE     = 5'd5,
    S_WALK_STEP   = 5'd6,   // move both lines toward (tgt_d, tgt_f), <= MAX_TAP_STEP each
    S_WALK_WAIT   = 5'd7,
    S_WALK_FINAL  = 5'd8,   // settle, then go to walk_ret
    S_DONE        = 5'd9,
    S_FAIL        = 5'd10,
    S_OVR_HOLD    = 5'd11,
    S_TRK_PROBE   = 5'd12,  // load the frame tap with `probe`
    S_TRK_SETTLE  = 5'd13,
    S_TRK_SAMPLE  = 5'd14,
    S_TRK_EVAL    = 5'd15,
    S_TRK_RIGHT   = 5'd16,  // frame back at center: start the right-edge search
    S_TRK_END     = 5'd17;  // frame settled at center: unfreeze, back to S_DONE

localparam [1:0] PH_CHECK = 2'd0, PH_LEFT = 2'd1, PH_RIGHT = 2'd2;

reg [4:0]                state;
reg [4:0]                walk_ret;   // state to enter when a walk has settled
reg [IDX_WIDTH-1:0]      idx;        // current sweep tap 0..SWEEP_TAPS-1
reg [IDX_WIDTH-1:0]      cnt;        // settle / sample down-counter
reg                      sample_acc; // AND of data_ok across the sample window
reg [SWEEP_TAPS-1:0]     good;       // good[k] = 1 -> tap k is inside an eye

assign good_map = good;

// Shadows of what each delay line holds (IDELAYE3 RST returns both to tap 0),
// and walk targets.
reg [IDX_WIDTH-1:0] cur_d, cur_f;
reg [IDX_WIDTH-1:0] tgt_d, tgt_f;
// Reference eye center (sweep result, then updated by tracking) and where the
// data line was when an override took it (restored on release).
reg [IDX_WIDTH-1:0] center;
reg [IDX_WIDTH-1:0] d_home;

// Linear longest-run analysis
reg [IDX_WIDTH-1:0] scan_pos;
reg [IDX_WIDTH-1:0] run_len, run_start;
reg [IDX_WIDTH-1:0] best_len, best_start;

// Tracking
reg [TMR_WIDTH-1:0] trk_timer;
reg [1:0]           trk_phase;
reg [IDX_WIDTH-1:0] probe;
reg [IDX_WIDTH-1:0] left_bad;

wire [IDX_WIDTH-1:0] run_len_next = good[scan_pos] ? (run_len + 1'b1)
                                                   : {IDX_WIDTH{1'b0}};
wire [IDX_WIDTH-1:0] eye_center   = best_start + (best_len >> 1);

// Next hop of each line toward its target, at most MAX_TAP_STEP.
function [IDX_WIDTH-1:0] hop(input [IDX_WIDTH-1:0] from, input [IDX_WIDTH-1:0] to);
    reg [IDX_WIDTH-1:0] diff;
    begin
        diff = (to > from) ? (to - from) : (from - to);
        if (diff > MAX_TAP_STEP[IDX_WIDTH-1:0]) diff = MAX_TAP_STEP[IDX_WIDTH-1:0];
        hop = (to > from) ? (from + diff) : (from - diff);
    end
endfunction

wire [IDX_WIDTH-1:0] next_d = hop(cur_d, tgt_d);
wire [IDX_WIDTH-1:0] next_f = hop(cur_f, tgt_f);

// Tracking result for the measured edges (left_bad, probe = right_bad).
wire [IDX_WIDTH-1:0] trk_width  = probe - left_bad - 1'b1;
wire [IDX_WIDTH-1:0] trk_center = left_bad + ((probe - left_bad) >> 1);

// Data target = center + signed offset, clamped to the delay line.
wire signed [IDX_WIDTH+1:0] d_target_raw = $signed({2'b00, trk_center}) +
                                           $signed({{(IDX_WIDTH-6){trk_offset[7]}}, trk_offset});
wire [IDX_WIDTH-1:0] d_target = d_target_raw[IDX_WIDTH+1] ? {IDX_WIDTH{1'b0}} :
                                (d_target_raw > $signed({2'b00, TAP_MAX})) ? TAP_MAX :
                                d_target_raw[IDX_WIDTH-1:0];
wire signed [IDX_WIDTH+1:0] d_delta = $signed({2'b00, d_target}) - $signed({2'b00, cur_d});
wire [IDX_WIDTH+1:0]        d_dist  = d_delta[IDX_WIDTH+1] ? -d_delta : d_delta;
wire signed [IDX_WIDTH+1:0] d_step  = (d_dist <= trk_deadband)   ? 0 :
                                      (d_delta >  TRACK_MAX_STEP) ? TRACK_MAX_STEP :
                                      (d_delta < -TRACK_MAX_STEP) ? -TRACK_MAX_STEP : d_delta;

wire trk_due = (trk_timer >= {trk_interval, {TRACK_TICK_SHIFT{1'b0}}});

always @(posedge clk) begin
    if (reset) begin
        state          <= S_IDLE;
        walk_ret       <= S_DONE;
        data_tap       <= 9'd0;
        data_load      <= 1'b0;
        frame_tap      <= 9'd0;
        frame_load     <= 1'b0;
        align_done     <= 1'b0;
        align_fail     <= 1'b0;
        align_phase    <= 16'd0;
        eye_width      <= 16'd0;
        idx            <= {IDX_WIDTH{1'b0}};
        cnt            <= {IDX_WIDTH{1'b0}};
        good           <= {SWEEP_TAPS{1'b0}};
        sample_acc     <= 1'b1;
        cur_d          <= {IDX_WIDTH{1'b0}};
        cur_f          <= {IDX_WIDTH{1'b0}};
        tgt_d          <= {IDX_WIDTH{1'b0}};
        tgt_f          <= {IDX_WIDTH{1'b0}};
        center         <= {IDX_WIDTH{1'b0}};
        d_home         <= {IDX_WIDTH{1'b0}};
        ovr_active     <= 1'b0;
        bitslip_freeze <= 1'b0;
        trk_busy       <= 1'b0;
        trk_timer      <= {TMR_WIDTH{1'b0}};
        trk_phase      <= PH_CHECK;
        probe          <= {IDX_WIDTH{1'b0}};
        left_bad       <= {IDX_WIDTH{1'b0}};
        trk_count      <= 16'd0;
        trk_last_move  <= 8'd0;
        trk_err_count  <= 8'd0;
        trk_left       <= 9'd0;
        trk_right      <= 9'd0;
    end else begin
        data_load  <= 1'b0;   // pulsed for exactly one cycle where a line is loaded
        frame_load <= 1'b0;

        case (state)
        // ----------------------------------------------------------------
        S_IDLE: begin
            align_done <= 1'b0;
            align_fail <= 1'b0;
            idx        <= {IDX_WIDTH{1'b0}};
            good       <= {SWEEP_TAPS{1'b0}};
            if (start) state <= S_LOAD;
        end

        // Sweep: load tap = idx into both lines, then dwell.
        S_LOAD: begin
            data_tap   <= idx[8:0];
            frame_tap  <= idx[8:0];
            data_load  <= 1'b1;
            frame_load <= 1'b1;
            cur_d      <= idx;
            cur_f      <= idx;
            cnt        <= SETTLE_CYCLES[IDX_WIDTH-1:0];
            state      <= S_SETTLE;
        end

        S_SETTLE: begin
            if (cnt != {IDX_WIDTH{1'b0}})
                cnt <= cnt - 1'b1;
            else begin
                cnt        <= SAMPLE_CYCLES[IDX_WIDTH-1:0];
                sample_acc <= 1'b1;
                state      <= S_SAMPLE;
            end
        end

        S_SAMPLE: begin
            sample_acc <= sample_acc & data_ok;
            if (cnt != {IDX_WIDTH{1'b0}})
                cnt <= cnt - 1'b1;
            else begin
                good[idx] <= sample_acc & data_ok;
                state     <= S_NEXT;
            end
        end

        S_NEXT: begin
            if (idx == (SWEEP_TAPS-1)) begin
                scan_pos   <= {IDX_WIDTH{1'b0}};
                run_len    <= {IDX_WIDTH{1'b0}};
                run_start  <= {IDX_WIDTH{1'b0}};
                best_len   <= {IDX_WIDTH{1'b0}};
                best_start <= {IDX_WIDTH{1'b0}};
                state      <= S_ANALYZE;
            end else begin
                idx   <= idx + 1'b1;
                state <= S_LOAD;
            end
        end

        // Linear longest-run-of-1s over good[] (first run wins a tie).
        S_ANALYZE: begin
            if (scan_pos < SWEEP_TAPS[IDX_WIDTH-1:0]) begin
                run_len <= run_len_next;
                if (good[scan_pos] && (run_len == {IDX_WIDTH{1'b0}}))
                    run_start <= scan_pos;
                if (run_len_next > best_len) begin
                    best_len   <= run_len_next;
                    best_start <= (run_len == {IDX_WIDTH{1'b0}}) ? scan_pos : run_start;
                end
                scan_pos <= scan_pos + 1'b1;
            end else begin
                eye_width <= {{(16-IDX_WIDTH){1'b0}}, best_len};
                if (best_len < MIN_EYE_TAPS[IDX_WIDTH-1:0]) begin
                    state <= S_FAIL;
                end else begin
                    align_phase <= {{(16-IDX_WIDTH){1'b0}}, eye_center};
                    center      <= eye_center;
                    tgt_d       <= eye_center;
                    tgt_f       <= eye_center;
                    walk_ret    <= S_DONE;
                    state       <= S_WALK_STEP;
                end
            end
        end

        // ---- Walk both lines to (tgt_d, tgt_f), <= MAX_TAP_STEP per LOAD each ----
        S_WALK_STEP: begin
            if ((cur_d == tgt_d) && (cur_f == tgt_f)) begin
                cnt   <= SETTLE_CYCLES[IDX_WIDTH-1:0];
                state <= S_WALK_FINAL;
            end else begin
                if (cur_d != tgt_d) begin
                    data_tap  <= next_d[8:0];
                    data_load <= 1'b1;
                    cur_d     <= next_d;
                end
                if (cur_f != tgt_f) begin
                    frame_tap  <= next_f[8:0];
                    frame_load <= 1'b1;
                    cur_f      <= next_f;
                end
                cnt   <= SETTLE_CYCLES[IDX_WIDTH-1:0];
                state <= S_WALK_WAIT;
            end
        end

        // Inter-hop spacing (>= the 4-cycle COUNT-mode LOAD-to-LOAD minimum).
        S_WALK_WAIT: begin
            if (cnt != {IDX_WIDTH{1'b0}})
                cnt <= cnt - 1'b1;
            else
                state <= S_WALK_STEP;
        end

        // Let the lines + capture pipeline settle at the destination.
        S_WALK_FINAL: begin
            if (cnt != {IDX_WIDTH{1'b0}})
                cnt <= cnt - 1'b1;
            else begin
                if (walk_ret == S_DONE) ovr_active <= 1'b0;
                state <= walk_ret;
            end
        end

        // ---- Aligned. Override takes priority over tracking. ----
        S_DONE: begin
            align_done <= 1'b1;
            if (ovr_en) begin
                d_home     <= cur_d;
                tgt_d      <= {{(IDX_WIDTH-9){1'b0}}, ovr_tap};
                tgt_f      <= {{(IDX_WIDTH-9){1'b0}}, ovr_tap};
                ovr_active <= 1'b1;
                walk_ret   <= S_OVR_HOLD;
                trk_timer  <= {TMR_WIDTH{1'b0}};
                state      <= S_WALK_STEP;
            end else if (trk_en) begin
                if (trk_due) begin
                    trk_timer      <= {TMR_WIDTH{1'b0}};
                    bitslip_freeze <= 1'b1;
                    trk_busy       <= 1'b1;
                    trk_phase      <= PH_CHECK;
                    probe          <= cur_f;   // first, re-check the current center
                    state          <= S_TRK_PROBE;
                end else
                    trk_timer <= trk_timer + 1'b1;
            end else
                trk_timer <= {TMR_WIDTH{1'b0}};
        end

        // Holding an override tap: retarget on a new ovr_tap; on release walk back.
        S_OVR_HOLD: begin
            if (!ovr_en) begin
                tgt_d    <= d_home;
                tgt_f    <= center;
                walk_ret <= S_DONE;
                state    <= S_WALK_STEP;
            end else if ({{(IDX_WIDTH-9){1'b0}}, ovr_tap} != tgt_f) begin
                tgt_d <= {{(IDX_WIDTH-9){1'b0}}, ovr_tap};
                tgt_f <= {{(IDX_WIDTH-9){1'b0}}, ovr_tap};
                state <= S_WALK_STEP;
            end
        end

        // ---- Tracking: measure one frame tap ----
        S_TRK_PROBE: begin
            frame_tap  <= probe[8:0];
            frame_load <= 1'b1;
            cur_f      <= probe;
            cnt        <= SETTLE_CYCLES[IDX_WIDTH-1:0];
            state      <= S_TRK_SETTLE;
        end

        S_TRK_SETTLE: begin
            if (cnt != {IDX_WIDTH{1'b0}})
                cnt <= cnt - 1'b1;
            else begin
                cnt        <= SAMPLE_CYCLES[IDX_WIDTH-1:0];
                sample_acc <= 1'b1;
                state      <= S_TRK_SAMPLE;
            end
        end

        S_TRK_SAMPLE: begin
            sample_acc <= sample_acc & data_ok;
            if (cnt != {IDX_WIDTH{1'b0}})
                cnt <= cnt - 1'b1;
            else
                state <= S_TRK_EVAL;
        end

        // sample_acc = this probe tap was good for the whole window.
        S_TRK_EVAL: begin
            case (trk_phase)
            PH_CHECK: begin
                if (!sample_acc) begin
                    // Lost the eye at the current center: give up this cycle.
                    if (trk_err_count != 8'hFF) trk_err_count <= trk_err_count + 1'b1;
                    tgt_d    <= cur_d;
                    tgt_f    <= center;
                    walk_ret <= S_TRK_END;
                    state    <= S_WALK_STEP;
                end else if (center == {IDX_WIDTH{1'b0}}) begin
                    if (trk_err_count != 8'hFF) trk_err_count <= trk_err_count + 1'b1;
                    walk_ret <= S_TRK_END;
                    tgt_d    <= cur_d;
                    tgt_f    <= center;
                    state    <= S_WALK_STEP;
                end else begin
                    trk_phase <= PH_LEFT;
                    probe     <= center - 1'b1;
                    state     <= S_TRK_PROBE;
                end
            end

            PH_LEFT: begin
                if (!sample_acc) begin
                    // First bad tap below the center: walk back, then search right.
                    left_bad <= probe;
                    tgt_d    <= cur_d;
                    tgt_f    <= center;
                    walk_ret <= S_TRK_RIGHT;
                    state    <= S_WALK_STEP;
                end else if (probe == {IDX_WIDTH{1'b0}}) begin
                    // Good all the way to tap 0: no left edge to measure.
                    if (trk_err_count != 8'hFF) trk_err_count <= trk_err_count + 1'b1;
                    tgt_d    <= cur_d;
                    tgt_f    <= center;
                    walk_ret <= S_TRK_END;
                    state    <= S_WALK_STEP;
                end else begin
                    probe <= probe - 1'b1;
                    state <= S_TRK_PROBE;
                end
            end

            default: begin // PH_RIGHT
                if (!sample_acc) begin
                    // probe = first bad tap above the center: edges complete.
                    if (trk_width < MIN_EYE_TAPS[IDX_WIDTH-1:0]) begin
                        if (trk_err_count != 8'hFF) trk_err_count <= trk_err_count + 1'b1;
                        tgt_d <= cur_d;
                        tgt_f <= center;
                    end else begin
                        trk_left      <= left_bad[8:0];
                        trk_right     <= probe[8:0];
                        align_phase   <= {{(16-IDX_WIDTH){1'b0}}, trk_center};
                        eye_width     <= {{(16-IDX_WIDTH){1'b0}}, trk_width};
                        center        <= trk_center;
                        trk_count     <= trk_count + 1'b1;
                        trk_last_move <= d_step[7:0];
                        tgt_d         <= cur_d + d_step[IDX_WIDTH-1:0];
                        tgt_f         <= trk_center;
                    end
                    walk_ret <= S_TRK_END;
                    state    <= S_WALK_STEP;
                end else if (probe == TAP_MAX) begin
                    // Good all the way to the top: no right edge to measure.
                    if (trk_err_count != 8'hFF) trk_err_count <= trk_err_count + 1'b1;
                    tgt_d    <= cur_d;
                    tgt_f    <= center;
                    walk_ret <= S_TRK_END;
                    state    <= S_WALK_STEP;
                end else begin
                    probe <= probe + 1'b1;
                    state <= S_TRK_PROBE;
                end
            end
            endcase
        end

        // Frame tap is back at the center: search upward from center + 1.
        S_TRK_RIGHT: begin
            trk_phase <= PH_RIGHT;
            if (center == TAP_MAX) begin
                if (trk_err_count != 8'hFF) trk_err_count <= trk_err_count + 1'b1;
                state <= S_TRK_END;
            end else begin
                probe <= center + 1'b1;
                state <= S_TRK_PROBE;
            end
        end

        // Frame tap settled back at the center: release the bitslip.
        S_TRK_END: begin
            bitslip_freeze <= 1'b0;
            trk_busy       <= 1'b0;
            state          <= S_DONE;
        end

        S_FAIL: begin
            align_fail <= 1'b1;
        end

        default: state <= S_IDLE;
        endcase
    end
end

endmodule
`default_nettype wire

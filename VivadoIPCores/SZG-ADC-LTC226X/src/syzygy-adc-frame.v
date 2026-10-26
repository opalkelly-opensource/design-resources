`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-adc-frame.v
//
// Deserializes the ADC frame signal and derives the bitslip count that aligns
// the data ISERDES outputs.
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

module syzygy_adc_frame (
    input  wire        adc_data_clk, //divided decode clock
    input  wire        reset,
    input  wire        ena,
    input  wire        adc_bufio_clk,
    input  wire        adc_fr_p,
    input  wire        adc_fr_n,

    // Frame-lane IDELAYE3 tap control (VAR_LOAD / COUNT) from idelay_align. The
    // frame and data lanes are matched at the ADC, so frame_ok at a tap reflects
    // the data eye at that tap.
    input  wire        idelay_clk,
    input  wire [8:0]  idelay_tap,
    input  wire        idelay_load,
    output wire [8:0]  idelay_cntvalue,  // CNTVALUEOUT, idelay_clk domain

    output reg         data_valid,
    output wire        frame_ok,
    output wire [3:0]  bitslip_count,

    input  wire        bitslip_freeze    // hold bitslip_count while the tracker probes
    );

wire [3:0] bitslip_count_live;   // bitslip_detect output, 4'd15 = no match
wire frame_input, frame_delay;
wire [7:0] frame_serdes;

// frame_ok is the live match of the frame word against the training pattern
// rotations. The eye-centering FSM uses it as its per-tap quality signal, so it
// must fall at every tap that does not capture cleanly.
assign frame_ok = (bitslip_count_live != 4'd15);

// The data path follows the last count that matched, so a transient frame-word
// error holds the existing alignment. It is frozen while the tracker probes: a
// probe tap in the neighbouring eye matches a different rotation.
reg [3:0] bitslip_count_hold;
always @(posedge adc_data_clk or posedge reset) begin
    if (reset == 1'b1)
        bitslip_count_hold <= 4'd0;
    else if (ena && frame_ok && !bitslip_freeze)
        bitslip_count_hold <= bitslip_count_live;
end
assign bitslip_count = bitslip_count_hold;

// Hold data_valid low for the first few cycles after enable so the frame
// ISERDES + bitslip pipeline fills before data is declared valid.
reg  [2:0] wait_count = 3'd0;

always @(posedge adc_data_clk or posedge reset) begin
    if (reset == 1'b1) begin
        data_valid <= 1'b0;
        wait_count <= 3'd0;
    end 
    else if (ena) begin
        if (wait_count != 3'd4) begin
            wait_count <= wait_count + 1'b1;
            data_valid <= 1'b0;
        end
        else begin
            data_valid <= 1'b1;
        end
    end
    else begin
       data_valid <= 1'b0;
    end
end

IBUFDS #(
    .DIFF_TERM ("TRUE"),
    .IOSTANDARD ("LVDS")
) frame_ibufds (
    .I  (adc_fr_p),
    .IB (adc_fr_n),
    .O  (frame_input)
);

IDELAYE3 #(
    .CASCADE          ("NONE"),
    .DELAY_FORMAT     ("COUNT"),
    .DELAY_SRC        ("IDATAIN"),
    .DELAY_TYPE       ("VAR_LOAD"),
    .DELAY_VALUE      (0),          // taps (COUNT mode), not ps
    .IS_CLK_INVERTED  (1'b0),
    .IS_RST_INVERTED  (1'b0),
    .REFCLK_FREQUENCY (300.0),      // unused in COUNT mode; UG571 p172 says leave at default
    .SIM_DEVICE       ("ULTRASCALE_PLUS"),
    .UPDATE_MODE      ("ASYNC")
) frame_idelay (
    .CASC_OUT    (),
    .CASC_RETURN (1'b0),
    .CASC_IN     (1'b0),
    .CE          (1'b0),
    .CLK         (idelay_clk),
    .INC         (1'b0),
    .LOAD        (idelay_load),
    .CNTVALUEIN  (idelay_tap),
    .CNTVALUEOUT (idelay_cntvalue),
    .DATAIN      (1'b0),
    .IDATAIN     (frame_input),
    .DATAOUT     (frame_delay),
    .EN_VTC      (1'b0),            // COUNT mode: must be tied Low (UG571)
    .RST         (reset)
);

ISERDESE3 #(
      .DATA_WIDTH(8),
      .FIFO_ENABLE("FALSE"),
      .FIFO_SYNC_MODE("FALSE"),
      .IS_CLK_B_INVERTED(1'b1),       // CLK_B = inverted CLK
      .IS_CLK_INVERTED(1'b0),
      .IS_RST_INVERTED(1'b0),
      .SIM_DEVICE("ULTRASCALE_PLUS")
   )
   frame_iserdes (
      .FIFO_EMPTY(),
      .INTERNAL_DIVCLK(),
      .Q(frame_serdes),
      .CLK(adc_bufio_clk),
      .CLKDIV(adc_data_clk),
      .CLK_B(adc_bufio_clk),
      .D(frame_delay),
      .FIFO_RD_CLK(),
      .FIFO_RD_EN(),
      .RST(reset)
   );

bitslip_detect bitslip_detect(
    .clk_div        (adc_data_clk),
    .data_in        (frame_serdes),
    .reset          (reset),
    .ena            (ena),
    .bitslip_count  (bitslip_count_live)
);
endmodule
`default_nettype wire



`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-adc-phy.v
//
// Deserializes the two LTC2264-12 / LTC2268-14 LVDS data lanes of one channel
// into a 16-bit sample. Both lanes share one IDELAYE3 tap (VAR_LOAD / COUNT):
// the lanes are matched at the ADC, so one delay centers them all.
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

module syzygy_adc_phy (
    input  wire                reset,
    input  wire [1:0]          adc_data_p, // Channel data
    input  wire [1:0]          adc_data_n,
    input  wire                adc_bufio_clk,
    input  wire                adc_data_clk,
    input  wire [3:0]          bitslip_count,
    input  wire                ena,

    // IDELAYE3 tap control from idelay_align
    input  wire                idelay_clk,     // IDELAYE3 CLK (load/tap-count domain)
    input  wire [8:0]          idelay_tap,     // tap to load on idelay_load (CNTVALUEIN)
    input  wire                idelay_load,    // 1-cycle load strobe
    output wire [8:0]          idelay_cntvalue, // lane 1 CNTVALUEOUT

    output wire [15:0]         adc_data_out
    );

wire lane1_ser, lane2_ser;   // IBUFDS outputs (pre-delay)
wire lane1_del, lane2_del;   // IDELAYE3 outputs (delayed -> ISERDES)
wire [7:0] lane1_q, lane2_q;

IBUFDS #(
    .DIFF_TERM ("TRUE"),
    .IOSTANDARD ("LVDS")
) lane1_ibufds (
    .I  (adc_data_p[0]),
    .IB (adc_data_n[0]),
    .O  (lane1_ser)
);

IBUFDS #(
    .DIFF_TERM ("TRUE"),
    .IOSTANDARD ("LVDS")
) lane2_ibufds (
    .I  (adc_data_p[1]),
    .IB (adc_data_n[1]),
    .O  (lane2_ser)
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
) lane1_idelay (
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
    .IDATAIN     (lane1_ser),
    .DATAOUT     (lane1_del),
    .EN_VTC      (1'b0),            // COUNT mode: must be tied Low (UG571)
    .RST         (reset)
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
) lane2_idelay (
    .CASC_OUT    (),
    .CASC_RETURN (1'b0),
    .CASC_IN     (1'b0),
    .CE          (1'b0),
    .CLK         (idelay_clk),
    .INC         (1'b0),
    .LOAD        (idelay_load),
    .CNTVALUEIN  (idelay_tap),
    .CNTVALUEOUT (),
    .DATAIN      (1'b0),
    .IDATAIN     (lane2_ser),
    .DATAOUT     (lane2_del),
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
   lane1_serdes (
      .FIFO_EMPTY(),
      .INTERNAL_DIVCLK(),
      .Q(lane1_q),
      .CLK(adc_bufio_clk),
      .CLKDIV(adc_data_clk),
      .CLK_B(adc_bufio_clk),
      .D(lane1_del),
      .FIFO_RD_CLK(),
      .FIFO_RD_EN(),
      .RST(reset)
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
   lane2_serdes (
      .FIFO_EMPTY(),
      .INTERNAL_DIVCLK(),
      .Q(lane2_q),
      .CLK(adc_bufio_clk),
      .CLKDIV(adc_data_clk),
      .CLK_B(adc_bufio_clk),
      .D(lane2_del),
      .FIFO_RD_CLK(),
      .FIFO_RD_EN(),
      .RST(reset)
   );

// De-interleave the two lanes into the 16-bit sample: adc_data_p[0] carries the
// odd bits, adc_data_p[1] the even bits (LTC 2-lane, 16-bit serialization;
// verified on hardware).
bitslip_shift lane1_bitslip(
    .clk_div        (adc_data_clk),
    .data_in        (lane1_q),
    .ena            (ena),
    .reset          (reset),
    .bitslip_count  (bitslip_count),
    .data_out       ({adc_data_out[1], adc_data_out[3], adc_data_out[5], adc_data_out[7],
                     adc_data_out[9], adc_data_out[11], adc_data_out[13], adc_data_out[15]})
    );

bitslip_shift lane2_bitslip(
    .clk_div        (adc_data_clk),
    .data_in        (lane2_q),
    .ena            (ena),
    .reset          (reset),
    .bitslip_count  (bitslip_count),
    .data_out       ({adc_data_out[0], adc_data_out[2], adc_data_out[4], adc_data_out[6],
                      adc_data_out[8], adc_data_out[10], adc_data_out[12], adc_data_out[14]})
    );

endmodule
`default_nettype wire

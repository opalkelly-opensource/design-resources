`timescale 1ns / 1ps

//------------------------------------------------------------------------
// syzygy-dac-phy.v
//
// Physical interface to the DAC, combining the I and Q data signals into
// a single DDR interface.
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

module syzygy_dac_phy(
	input  wire        clk,
	input  wire        reset,

	input  wire [11:0] data_i,
	input  wire [11:0] data_q,

	output wire [11:0] dac_data,
	output wire        dac_clk
);
// Per-bit DDR output: ODDRE1.Q feeds the OBUF directly (no delay/SERDES stage).
wire [11:0] data_ddr;

// Reset code. A reset pulses RESET/PINMD, so the AD911x is in its power-on
// (offset binary) format regardless of DAC_SAMPLE_FORMAT and mid-scale is 12'h800.
// 12'h000 would park the outputs at negative full scale through every reset, which
// matters for the pod's DC-coupled op-amp build. The format-dependent idle code is
// applied downstream in syzygy-dac-axi-stream.v; this covers the reset window only.
localparam [11:0] DAC_IDLE_CODE_POR = 12'h800;

// Register the I/Q samples into the clk domain before the DDR output mux.
reg  [11:0] data_i_r, data_q_r;

always @(posedge clk) begin
	if (reset) begin
		data_i_r <= DAC_IDLE_CODE_POR;
		data_q_r <= DAC_IDLE_CODE_POR;
	end else begin
		data_i_r <= data_i;
		data_q_r <= data_q;
	end
end

  genvar pin_count;
  generate for (pin_count = 0; pin_count < 12; pin_count = pin_count + 1) begin: pins
    OBUF
      #(.IOSTANDARD ("LVCMOS18"))
     obuf_inst
       (.O          (dac_data    [pin_count]),
        .I          (data_ddr    [pin_count]));

   ODDRE1 #(
      .IS_C_INVERTED(1'b0),
      .IS_D1_INVERTED(1'b0),
      .IS_D2_INVERTED(1'b0),
      .SIM_DEVICE("ULTRASCALE_PLUS"),
      .SRVAL(DAC_IDLE_CODE_POR[pin_count])
   )
   ODDRE1_inst (
      .Q(data_ddr[pin_count]),
      .C(clk),
      .D1(data_q_r[pin_count]),   // Q on the falling edge
      .D2(data_i_r[pin_count]),   // I on the rising edge
      .SR(reset)
   );

   end
endgenerate

wire dac_clk_oddr;
ODDRE1 #(
   .IS_C_INVERTED(1'b0),
   .SIM_DEVICE("ULTRASCALE_PLUS"),
   .SRVAL(1'b0)
) oddr_dac_clk (
   .Q  (dac_clk_oddr),
   .C  (clk),
   .D1 (1'b1),
   .D2 (1'b0),
   .SR (1'b0)
);

OBUF #(.IOSTANDARD("LVCMOS18")) obuf_dac_clk (.I(dac_clk_oddr), .O(dac_clk));

endmodule

`default_nettype wire

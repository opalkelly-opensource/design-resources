//------------------------------------------------------------------------
// syzygy-dac-phy.v
//
// Physical interface to the DAC, combining the I and Q data signals into
// a single DDR interface.
// 
//------------------------------------------------------------------------
// Copyright (c) 2023 Opal Kelly Incorporated
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
   // width of the data for the FPGA
 parameter FPGA_W = 12;
   // width of the data for the DAC
 parameter DAC_W = 24;

assign dac_clk = clk;
// Signal declarations 
////------------------------------
// Before the buffer
wire   [FPGA_W-1:0] data_out_to_pins_int;
// Between the delay and serdes
wire   [FPGA_W-1:0] data_out_to_pins_predelay;
// Create the clock logic
wire        phy_clk, locked;
reg  [11:0] data_i_r, data_q_r;
 
always @(posedge phy_clk) begin
	if (reset) begin
		data_i_r <= 12'd0;
		data_q_r <= 12'd0;
	end else begin
		data_i_r <= data_i;
		data_q_r <= data_q;
	end
end

clk_wiz_0 phy_pll(
	// Clock out ports
	.clk_out1 (phy_clk),
	// Status and control signals
	.reset    (reset),
	.locked   (locked),
	// Clock in ports
	.clk_in1  (clk)
);

  genvar pin_count;
  generate for (pin_count = 0; pin_count < FPGA_W; pin_count = pin_count + 1) begin: pins
    // Instantiate the buffers
    ////------------------------------
    // Instantiate a buffer for every bit of the data bus
    OBUF
      #(.IOSTANDARD ("LVCMOS18"))
     obuf_inst
       (.O          (dac_data    [pin_count]),
        .I          (data_out_to_pins_int[pin_count]));

    // Pass through the delay
    ////-------------------------------
   assign data_out_to_pins_int[pin_count]    = data_out_to_pins_predelay[pin_count];
   // ODDRE1: Dedicated Double Data Rate (DDR) Output Register
   //         Kintex UltraScale+
   // Xilinx HDL Language Template, version 2021.1

   ODDRE1 #(
      .IS_C_INVERTED(1'b0),           // Optional inversion for C
      .IS_D1_INVERTED(1'b0),          // Unsupported, do not use
      .IS_D2_INVERTED(1'b0),          // Unsupported, do not use
      .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version for simulation functionality (ULTRASCALE,
                                      // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
      .SRVAL(1'b0)                    // Initializes the ODDRE1 Flip-Flops to the specified value (1'b0, 1'b1)
   )
   ODDRE1_inst (
      .Q(data_out_to_pins_predelay[pin_count]),   // 1-bit output: Data output to IOB
      .C(clk),   // 1-bit input: High-speed clock input
      .D1(data_q_r[pin_count]), // 1-bit input: Parallel data input 1
      .D2(data_i_r[pin_count]), // 1-bit input: Parallel data input 2
      .SR(~locked)  // 1-bit input: Active-High Async Reset
   );

   end
endgenerate
endmodule

`default_nettype wire

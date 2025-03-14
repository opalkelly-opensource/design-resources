//------------------------------------------------------------------------
// syzygy-adc-phy.v
//
// This PHY interface converts the serial LVDS data streams out of the
// LTC2264-12 / LTC2268-14 into a parallel data output for use in the 
// FPGA design. Xilinx US+ ISERDESE3 blocks are used to deserialize 
// the ADC data. Bitslip operations are performed on the data to align    
// the DDR data.
//------------------------------------------------------------------------
// Copyright (c) 2024 Opal Kelly Incorporated
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
    input  wire [1:0]          adc_out_p, // Channel data
    input  wire [1:0]          adc_out_n,
    input  wire                adc_bufio_clk,
    input  wire                adc_slow_clk,
    input  wire [3:0]          bitslip_count,
    input  wire                ena,
    output wire [15:0]         adc_data_out
    );

wire [1:0] adc_out, adc_delay;
wire [7:0] adc_data_1, adc_data_2;

IBUFDS #(
    .DIFF_TERM ("TRUE"),
    .IOSTANDARD ("LVDS")
) adc_ibufds0 (
    .I  (adc_out_p[0]),
    .IB (adc_out_n[0]),
    .O  (adc_out[0])
);

IBUFDS #(
    .DIFF_TERM ("TRUE"),
    .IOSTANDARD ("LVDS")
) adc_ibufds1 (
    .I  (adc_out_p[1]),
    .IB (adc_out_n[1]),
    .O  (adc_out[1])
);

ISERDESE3 #(
      .DATA_WIDTH(8),                 // Parallel data width (4,8)
      .FIFO_ENABLE("FALSE"),          // Enables the use of the FIFO
      .FIFO_SYNC_MODE("FALSE"),       // Always set to FALSE. TRUE is reserved for later use.
      .IS_CLK_B_INVERTED(1'b1),       // Optional inversion for CLK_B. 1 = internal inversion
      .IS_CLK_INVERTED(1'b0),         // Optional inversion for CLK
      .IS_RST_INVERTED(1'b0),         // Optional inversion for RST
      .SIM_DEVICE("ULTRASCALE_PLUS")  // Set the device version for simulation functionality (ULTRASCALE,
                                      // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
   )
   channel1_lane1_SERDES (
      .FIFO_EMPTY(),            // 1-bit output: FIFO empty flag
      .INTERNAL_DIVCLK(),       // 1-bit output: Internally divided down clock used when FIFO is
                                // disabled (do not connect)
      .Q(adc_data_1),           // 8-bit registered output
      .CLK(adc_bufio_clk),      // 1-bit input: High-speed clock
      .CLKDIV(adc_slow_clk),    // 1-bit input: Divided Clock
      .CLK_B(adc_bufio_clk),    // 1-bit input: Inversion of High-speed clock CLK
      .D(adc_out[0]),         // 1-bit input: Serial Data Input
      .FIFO_RD_CLK(),           // 1-bit input: FIFO read clock
      .FIFO_RD_EN(),            // 1-bit input: Enables reading the FIFO when asserted
      .RST(reset)               // 1-bit input: Asynchronous Reset
   );

ISERDESE3 #(
      .DATA_WIDTH(8),                 // Parallel data width (4,8)
      .FIFO_ENABLE("FALSE"),          // Enables the use of the FIFO
      .FIFO_SYNC_MODE("FALSE"),       // Always set to FALSE. TRUE is reserved for later use.
      .IS_CLK_B_INVERTED(1'b1),       // Optional inversion for CLK_B 1 = internal inversion
      .IS_CLK_INVERTED(1'b0),         // Optional inversion for CLK
      .IS_RST_INVERTED(1'b0),         // Optional inversion for RST
      .SIM_DEVICE("ULTRASCALE_PLUS")  // Set the device version for simulation functionality (ULTRASCALE,
                                      // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
   )
   channel1_lane2_SERDES (
      .FIFO_EMPTY(),            // 1-bit output: FIFO empty flag
      .INTERNAL_DIVCLK(),       // 1-bit output: Internally divided down clock used when FIFO is
                                // disabled (do not connect)
      .Q(adc_data_2),           // 8-bit registered output
      .CLK(adc_bufio_clk),      // 1-bit input: High-speed clock
      .CLKDIV(adc_slow_clk),    // 1-bit input: Divided Clock
      .CLK_B(adc_bufio_clk),    // 1-bit input: Inversion of High-speed clock CLK
      .D(adc_out[1]),         // 1-bit input: Serial Data Input
      .FIFO_RD_CLK(),           // 1-bit input: FIFO read clock
      .FIFO_RD_EN(),            // 1-bit input: Enables reading the FIFO when asserted
      .RST(reset)               // 1-bit input: Asynchronous Reset
   );
bitslip_shift lane_1(
    .clk_div        (adc_slow_clk),
    .data_in        (adc_data_1),
    .ena            (ena),
    .reset          (reset),
    .bitslip_count  (bitslip_count),
    .data_out       ({adc_data_out[1], adc_data_out[3], adc_data_out[5], adc_data_out[7],
                     adc_data_out[9], adc_data_out[11], adc_data_out[13], adc_data_out[15]})
    );
    
bitslip_shift lane_2(
    .clk_div        (adc_slow_clk),
    .data_in        (adc_data_2),
    .ena            (ena),
    .reset          (reset),
    .bitslip_count  (bitslip_count),
    .data_out       ({adc_data_out[0], adc_data_out[2], adc_data_out[4], adc_data_out[6],
                      adc_data_out[8], adc_data_out[10], adc_data_out[12], adc_data_out[14]})
    );

endmodule
`default_nettype wire

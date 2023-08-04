//------------------------------------------------------------------------
// syzygy-adc-frame.v
//
// An ISERDES connected to the ADC frame signal is used by this module to
// generate bitslip signals used to align the ADC data ISERDES outputs.
// 
//------------------------------------------------------------------------
// Copyright (c) 2022-2023 Opal Kelly Incorporated
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
    input  wire        slow_clk, //divided decode clock
    input  wire        reset,
    input  wire        ena,
    input  wire        adc_bufio_clk,
    input  wire        adc_fr_p,
    input  wire        adc_fr_n,
    output reg         data_valid,
    output wire [3:0]  bitslip_count
    );

wire frame_input, frame_delay;
wire [7:0] frame_serdes;
// We must wait at least 4 clock cycles between each bitslip
reg  [2:0] wait_count = 3'd0;

always @(posedge slow_clk or posedge reset) begin
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

ISERDESE3 #(
      .DATA_WIDTH(8),                 // Parallel data width (4,8)
      .FIFO_ENABLE("FALSE"),          // Enables the use of the FIFO
      .FIFO_SYNC_MODE("FALSE"),       // Always set to FALSE. TRUE is reserved for later use.
      .IS_CLK_B_INVERTED(1'b1),       // Optional inversion for CLK_B
      .IS_CLK_INVERTED(1'b0),         // Optional inversion for CLK
      .IS_RST_INVERTED(1'b0),         // Optional inversion for RST
      .SIM_DEVICE("ULTRASCALE_PLUS")  // Set the device version for simulation functionality (ULTRASCALE,
                                      // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
   )
   channel1_lane2_SERDES (
      .FIFO_EMPTY(),            // 1-bit output: FIFO empty flag
      .INTERNAL_DIVCLK(),       // 1-bit output: Internally divided down clock used when FIFO is
                                // disabled (do not connect)
      .Q(frame_serdes),         // 8-bit registered output
      .CLK(adc_bufio_clk),      // 1-bit input: High-speed clock
      .CLKDIV(slow_clk),        // 1-bit input: Divided Clock
      .CLK_B(adc_bufio_clk),    // 1-bit input: Inversion of High-speed clock CLK
      .D(frame_input),          // 1-bit input: Serial Data Input
      .FIFO_RD_CLK(),           // 1-bit input: FIFO read clock
      .FIFO_RD_EN(),            // 1-bit input: Enables reading the FIFO when asserted
      .RST(reset)               // 1-bit input: Asynchronous Reset
   );

bitslip_detect bitslip_detect(
    .clk_div        (slow_clk),
    .data_in        (frame_serdes),
    .reset          (reset),
    .ena            (ena),
    .bitslip_count  (bitslip_count)
);
endmodule
`default_nettype wire



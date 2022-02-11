//------------------------------------------------------------------------
// syzygy-adc-frame.v
//
// An ISERDES connected to the ADC frame signal is used by this module to
// generate bitslip signals used to align the ADC data ISERDES outputs.
// 
//------------------------------------------------------------------------
// Copyright (c) 2021 Opal Kelly Incorporated
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
    .IOSTANDARD ("LVDS_25")
) frame_ibufds (
    .I  (adc_fr_p),
    .IB (adc_fr_n),
    .O  (frame_input)
);

IDELAYE3 #(
      .CASCADE("NONE"),               // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
      .DELAY_FORMAT("TIME"),          // Units of the DELAY_VALUE (COUNT, TIME)
      .DELAY_SRC("IDATAIN"),          // Delay input (DATAIN, IDATAIN)
      .DELAY_TYPE("FIXED"),           // Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
      .DELAY_VALUE(1030),             // Input delay value setting
      .IS_CLK_INVERTED(1'b0),         // Optional inversion for CLK
      .IS_RST_INVERTED(1'b0),         // Optional inversion for RST
      .REFCLK_FREQUENCY(300.0),       // IDELAYCTRL clock input frequency in MHz (200.0-800.0)
      .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version for simulation functionality (ULTRASCALE,
                                      // ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
      .UPDATE_MODE("ASYNC")           // Determines when updates to the delay will take effect (ASYNC, MANUAL,
                                      // SYNC)
   )
   adc_data_delay0 (
      .CASC_OUT(),              // 1-bit output: Cascade delay output to ODELAY input cascade
      .CNTVALUEOUT(),           // 9-bit output: Counter value output
      .DATAOUT(frame_delay),    // 1-bit output: Delayed data output
      .CASC_IN(),               // 1-bit input: Cascade delay input from slave ODELAY CASCADE_OUT
      .CASC_RETURN(),           // 1-bit input: Cascade delay returning from slave ODELAY DATAOUT
      .CE(1'b0),                // 1-bit input: Active-High enable increment/decrement input
      .CLK(1'b0),               // 1-bit input: Clock input Not necessary in FIXED mode.  
      .CNTVALUEIN(9'h00),       // 9-bit input: Counter value input
      .DATAIN(1'b0),            // 1-bit input: Data input from the logic
      .EN_VTC(1'b1),            // 1-bit input: Keep delay constant over VT
      .IDATAIN(frame_input),    // 1-bit input: Data input from the IOBUF
      .INC(1'b0),               // 1-bit input: Increment / Decrement tap delay input
      .LOAD(1'b0),              // 1-bit input: Load DELAY_VALUE input
      .RST(reset)               // 1-bit input: Asynchronous Reset to the DELAY_VALUE
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
      .D(frame_delay),          // 1-bit input: Serial Data Input
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



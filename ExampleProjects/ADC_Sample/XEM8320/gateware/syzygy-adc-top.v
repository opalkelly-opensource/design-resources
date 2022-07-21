//------------------------------------------------------------------------
// syzygy-adc-top.v
//
// This top level module integrates the various components of the
// LTC2264-12 / LTC2268-14 ADC portion of the design. These include 
// the ADC encode signal output, ADC data clock input, and ISERDES
// buffers to handle  data coming from the ADC. This example design
// uses the default ADC configuration, 2 lane 16 bit serialization. 
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

module syzygy_adc_top (
    input  wire                clk,
    input  wire                idelay_ref,
    input  wire                reset_async,
    input  wire                mmcm_locked,
    // ADC Pins
    input  wire [1:0]          adc_out_1p, // Channel 1 data
    input  wire [1:0]          adc_out_1n,
    input  wire [1:0]          adc_out_2p, // Channel 2 data
    input  wire [1:0]          adc_out_2n,
    input  wire                adc_dco_p,      // ADC Data clock
    input  wire                adc_dco_n,
    input  wire                adc_fr_p,       // Frame input
    input  wire                adc_fr_n,
    output wire                adc_encode_p,   // ADC Encode Clock
    //output wire                adc_encode_n,
    input  wire                adc_sdo,
    output wire                adc_sdi,
    output wire                adc_cs_n,
    output wire                adc_sck,
    output wire                adc_data_clk, // on a bitslip module.  
    output wire [15:0]         adc_data_1,
    output wire [15:0]         adc_data_2,
    output wire                data_valid,
    output wire                rdy,
    output wire [3:0] bitslip_count
    );
wire        bufio_clk;
wire        idelay_rdy;
//wire [3:0]  bitslip_count;

reg         reset_sync;
reg         delay_rdy = 1'b0;
reg [6:0]   reset_serdes_cnt = 7'd64;
reg         reset_idelay = 1'b0;
reg         reset_SERDES_hold = 1'b0;

// This example doesn't use the ADC SPI bus,
// the default settings work fine
assign adc_sdi  = 1'b1;
assign adc_cs_n = 1'b1;
assign adc_sck  = 1'b1;
assign rdy = delay_rdy;
// Logic reset logic. Order is as follows:
//      assert resets to PLLs, IDELAYs, IDELAYCTRL, SERDES.
//      wait MMCM_RSTMINPULSE (5ns) for us+

// Release order is as follows:
//      Release PLLs, wait for lock.
//      Release reset for IDELAYs, IDELAYCTRL, SERDES
//      wait for rdy signal from IDELAYCTRL.
//      wait >= 64 clock cycles
always @(posedge adc_data_clk or posedge reset_async) begin
    if(reset_async == 1'b1) begin
        reset_sync <= 1'b1;
        reset_idelay <= 1'b1;
        delay_rdy <= 1'b0;
        reset_SERDES_hold <= 1'b0;
        reset_serdes_cnt <= 7'd64;
    end 
    else begin
        if (mmcm_locked && reset_sync) begin
            reset_sync <= 1'b0;
            delay_rdy <= 1'b0;
            reset_idelay <= 1'b0;
            reset_SERDES_hold <= 1'b1;
            reset_serdes_cnt <= 7'd64;
        end
        if (reset_SERDES_hold && idelay_rdy) begin
             if (reset_serdes_cnt != 7'd0) begin
                  reset_serdes_cnt <= reset_serdes_cnt - 1'b1;
                  delay_rdy <= 1'b0;
             end
             else begin
                  delay_rdy <= 1'b1;
                  reset_SERDES_hold <= 1'b0;
             end
        end
    end
end

syzygy_adc_phy adc_phy1_impl (
    .reset         (reset_sync),
    .ena           (delay_rdy),
    .adc_out_p     (adc_out_1p),
    .adc_out_n     (adc_out_1n),
    .adc_bufio_clk (bufio_clk),
    .adc_slow_clk  (adc_data_clk),
    .bitslip_count (bitslip_count),
    .adc_data_out  (adc_data_1)
);

syzygy_adc_phy adc_phy2_impl (
    .reset         (reset_sync),
    .ena           (delay_rdy),
    .adc_out_p     (adc_out_2p),
    .adc_out_n     (adc_out_2n),
    .adc_bufio_clk (bufio_clk),
    .adc_slow_clk  (adc_data_clk),
    .bitslip_count (bitslip_count),
    .adc_data_out  (adc_data_2)
);

syzygy_adc_dco adc_dco_impl (
    .reset         (reset_async),
    .adc_dco_p     (adc_dco_p),
    .adc_dco_n     (adc_dco_n),
    .clk_out_bufio (bufio_clk),
    .clk_out_div   (adc_data_clk)
);

syzygy_adc_frame adc_frame_impl (
    .slow_clk      (adc_data_clk),
    .reset         (reset_sync),
    .adc_bufio_clk (bufio_clk),
    .adc_fr_p      (adc_fr_p),
    .adc_fr_n      (adc_fr_n),
    .bitslip_count (bitslip_count),
    .ena           (delay_rdy),
    .data_valid    (data_valid)
);

syzygy_adc_enc adc_enc_impl (
    .clk          (clk),
    .adc_encode_p (adc_encode_p)
    //.adc_encode_n (adc_encode_n)
);

IDELAYCTRL #(
    .SIM_DEVICE("ULTRASCALE")
) idelay_adc (
    .RST    (reset_idelay),
    .REFCLK (idelay_ref),
    .RDY    (idelay_rdy)
);

endmodule
`default_nettype wire

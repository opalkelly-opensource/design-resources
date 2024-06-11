// XEM8320 MultiDAQ Example Design
//
// Top level file for the SZG-MULTIDAQ example design.
// This design targets the SZG-MULTIDAQ on PORT-D on the
// XEM8320-AU25P.
//
//
// Clocking setup:
// + 100.8 MHz (okClk)
// + 14.28571 MHz (adc_sclk_int)
// + 26.31579 MHz (dac_sclk_in)
//
// WireIn    0x00      0 - Clock reset
//           0x00      1 - ADC hw reset
//           0x00      2 - Start ADC
//           0x00      3 - Sync Module reset
//           0x00   7: 4 - ADC channel count (0-7)
//           0x00  15: 8 - DAC channel count (One hot for each individual channel)
//           0x00     16 - DAC reset
//           0x01  31: 0 - DAC Ch1 frequency
//           ....  31: 0 - DAC Chx frequency
//           0x08  31: 0 - DAC Ch8 frequency
//
// WireOut   0x28      0 - Send FIFO full signal
// PipeOut   0xA0  31:16 - ADC channel number
//                 15: 0 - ADC Channel Data
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
`timescale 1ns / 1ps

module multidaq(
    input  wire [4:0]   okUH,
    output wire [2:0]   okHU,
    inout  wire [31:0]  okUHU,
    inout  wire         okAA,
    input  wire         sys_clkp,
    input  wire         sys_clkn,
    output wire         ADC_SDI_C,
    input  wire         ADC_SDO_C,
    output wire         ADC_SCLK_C,
    output wire         ADC_RST,
    output wire         ADC_CS_N_C,
    output wire         DAC_SDI_C,
    input  wire         DAC_SDO_C,
    output wire         DAC_SCLK_C,
    output wire         DAC_CS_N_C,
    
    output wire [5:0]   led
);

// Clock
wire sys_clk;
IBUFGDS osc_clk(.O(sys_clk), .I(sys_clkp), .IB(sys_clkn));

// Host interface bus:
wire         okClk;
wire [112:0] okHE;
wire [64:0]  okEH;

// Endpoint connections:
wire [31:0] wi00_ep_dataout;

// wires
wire [7:0] state_dbgw, state_dbgd;
wire [7:0] data_valid;
wire adc_sclk_int, dac_sclk_int;
wire adc_reset, adc_reset_sync, adc_auto_reset, adc_auto_reset_sync, sync_rst, dac_rst, dac_rst_sync;
wire reset, clk_reset, locked;
wire ch1_data_rdy, ch2_data_rdy, ch3_data_rdy, ch4_data_rdy, ch5_data_rdy, ch6_data_rdy, ch7_data_rdy, ch8_data_rdy;
wire [15:0] ch_data [7:0];
wire [15:0] dac_ch_data [7:0];
wire [15:0] ch_data_sync [7:0];
wire [31:0] ch1_data_dac, ch2_data_dac, ch3_data_dac, ch4_data_dac, ch5_data_dac, ch6_data_dac, ch7_data_dac, ch8_data_dac;
wire [31:0] ch1_freq, ch2_freq, ch3_freq, ch4_freq, ch5_freq, ch6_freq, ch7_freq, ch8_freq;
wire [31:0] ch1_freq_sync, ch2_freq_sync, ch3_freq_sync, ch4_freq_sync, ch5_freq_sync, ch6_freq_sync, ch7_freq_sync, ch8_freq_sync;
wire [31:0] wo28_ep_datain;
wire [3:0] adc_count;
wire [7:0] dac_en;
wire poa0_ep_read;
wire [31:0] poa0_ep_datain;
wire full;

// assigns
assign wo28_ep_datain = {31'd0, full};
assign led = {4'b1111, full, locked};
assign reset = wi00_ep_dataout[0];
assign adc_reset = wi00_ep_dataout[1];
assign adc_auto_reset = wi00_ep_dataout[2];
assign sync_rst = wi00_ep_dataout[3];
assign adc_count = wi00_ep_dataout[7:4];
assign dac_en = wi00_ep_dataout[15:8];
assign dac_rst = wi00_ep_dataout[16];

adc_serial_clk adc_clk_inst
   (
    // Clock out ports
    .clk_out1(adc_sclk_int),     // output clk_out1 (17 MHz)
    .clk_out2(dac_sclk_int),    // output clk_out2 (50 MHz)
    // Status and control signals
    .reset(reset), // input reset (async)
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(sys_clk)    // input clk
);

sync_reset adc_rst (
    .clk(adc_sclk_int),            // Connect to clock signal
    .async_reset(adc_auto_reset),  // Connect to asynchronous reset signal
    .sync_reset(adc_auto_reset_sync)     // Connect to synchronous reset signal
);

sync_reset adc_auto_rst (
    .clk(adc_sclk_int),            // Connect to clock signal
    .async_reset(adc_reset),  // Connect to asynchronous reset signal
    .sync_reset(adc_reset_sync)     // Connect to synchronous reset signal
);

sync_reset dac_rst_sync (
    .clk(dac_sclk_int),            // Connect to clock signal
    .async_reset(dac_rst),  // Connect to asynchronous reset signal
    .sync_reset(dac_rst_sync)     // Connect to synchronous reset signal
);

sync_bus #(
    .N(32)
) dac_sync_1 (
    .clk_src(okClk),
    .bus_src(ch1_freq),
    .reset(sync_rst),
    .clk_dst(dac_sclk_int),
    .bus_dst(ch1_freq_sync)
);

sync_bus #(
    .N(32)
) dac_sync_2 (
    .clk_src(okClk),
    .bus_src(ch2_freq),
    .reset(sync_rst),
    .clk_dst(dac_sclk_int),
    .bus_dst(ch2_freq_sync)
);

sync_bus #(
    .N(32)
) dac_sync_3 (
    .clk_src(okClk),
    .bus_src(ch3_freq),
    .reset(sync_rst),
    .clk_dst(dac_sclk_int),
    .bus_dst(ch3_freq_sync)
);

sync_bus #(
    .N(32)
) dac_sync_4 (
    .clk_src(okClk),
    .bus_src(ch4_freq),
    .reset(sync_rst),
    .clk_dst(dac_sclk_int),
    .bus_dst(ch4_freq_sync)
);

sync_bus #(
    .N(32)
) dac_sync_5 (
    .clk_src(okClk),
    .bus_src(ch5_freq),
    .reset(sync_rst),
    .clk_dst(dac_sclk_int),
    .bus_dst(ch5_freq_sync)
);

sync_bus #(
    .N(32)
) dac_sync_6 (
    .clk_src(okClk),
    .bus_src(ch6_freq),
    .reset(sync_rst),
    .clk_dst(dac_sclk_int),
    .bus_dst(ch6_freq_sync)
);

sync_bus #(
    .N(32)
) dac_sync_7 (
    .clk_src(okClk),
    .bus_src(ch7_freq),
    .reset(sync_rst),
    .clk_dst(dac_sclk_int),
    .bus_dst(ch7_freq_sync)
);

sync_bus #(
    .N(32)
) dac_sync_8 (
    .clk_src(okClk),
    .bus_src(ch8_freq),
    .reset(sync_rst),
    .clk_dst(dac_sclk_int),
    .bus_dst(ch8_freq_sync)
);

cordic cordic_inst1 (
    .clk(dac_sclk_int),           // Clock input
    .reset(1'b0),       // Reset input
    .output_en(locked & dac_en[0]),   // Disable output input
    .freq(ch1_freq_sync),         // Frequency input
    .data(ch1_data_dac)          // Data output
);

cordic cordic_inst2 (
    .clk(dac_sclk_int),           // Clock input
    .reset(1'b0),       // Reset input
    .output_en(locked & dac_en[1]),   // Disable output input
    .freq(ch2_freq_sync),         // Frequency input
    .data(ch2_data_dac)          // Data output
);

cordic cordic_inst3 (
    .clk(dac_sclk_int),           // Clock input
    .reset(1'b0),       // Reset input
    .output_en(locked & dac_en[2]),   // Disable output input
    .freq(ch3_freq_sync),         // Frequency input
    .data(ch3_data_dac)          // Data output
);

cordic cordic_inst4 (
    .clk(dac_sclk_int),           // Clock input
    .reset(1'b0),       // Reset input
    .output_en(locked & dac_en[3]),   // Disable output input
    .freq(ch4_freq_sync),         // Frequency input
    .data(ch4_data_dac)          // Data output
);

cordic cordic_inst5 (
    .clk(dac_sclk_int),           // Clock input
    .reset(1'b0),       // Reset input
    .output_en(locked & dac_en[4]),   // Disable output input
    .freq(ch5_freq_sync),         // Frequency input
    .data(ch5_data_dac)          // Data output
);

cordic cordic_inst6 (
    .clk(dac_sclk_int),           // Clock input
    .reset(1'b0),       // Reset input
    .output_en(locked & dac_en[5]),   // Disable output input
    .freq(ch6_freq_sync),         // Frequency input
    .data(ch6_data_dac)          // Data output
);

cordic cordic_inst7 (
    .clk(dac_sclk_int),           // Clock input
    .reset(1'b0),       // Reset input
    .output_en(locked & dac_en[6]),   // Disable output input
    .freq(ch7_freq_sync),         // Frequency input
    .data(ch7_data_dac)          // Data output
);

cordic cordic_inst8 (
    .clk(dac_sclk_int),           // Clock input
    .reset(1'b0),       // Reset input
    .output_en(locked & dac_en[7]),   // Disable output input
    .freq(ch8_freq_sync),         // Frequency input
    .data(ch8_data_dac)          // Data output
);

frontpanel_0 frontpanel_inst (
  .okUH(okUH),                        // input wire [4 : 0] okUH
  .okHU(okHU),                        // output wire [2 : 0] okHU
  .okUHU(okUHU),                      // inout wire [31 : 0] okUHU
  .okAA(okAA),                        // inout wire okAA
  .okClk(okClk),                      // output wire okClk
  .wi00_ep_dataout(wi00_ep_dataout),  // output wire [31 : 0] wi00_ep_dataout
  .wi01_ep_dataout(ch1_freq),  // output wire [31 : 0] wi01_ep_dataout
  .wi02_ep_dataout(ch2_freq),  // output wire [31 : 0] wi02_ep_dataout
  .wi03_ep_dataout(ch3_freq),  // output wire [31 : 0] wi03_ep_dataout
  .wi04_ep_dataout(ch4_freq),  // output wire [31 : 0] wi04_ep_dataout
  .wi05_ep_dataout(ch5_freq),  // output wire [31 : 0] wi05_ep_dataout
  .wi06_ep_dataout(ch6_freq),  // output wire [31 : 0] wi06_ep_dataout
  .wi07_ep_dataout(ch7_freq),  // output wire [31 : 0] wi07_ep_dataout
  .wi08_ep_dataout(ch8_freq),  // output wire [31 : 0] wi08_ep_dataout
  .wo28_ep_datain(wo28_ep_datain),
  .poa0_ep_datain({poa0_ep_datain[7:0], poa0_ep_datain[15:8], poa0_ep_datain[23:16], poa0_ep_datain[31:24]}),    // input wire [31 : 0] poa0_ep_datain
  .poa0_ep_read(poa0_ep_read)      // output wire poa0_ep_read
);

adc_controller adc_controller_inst (
    .rst(adc_reset_sync),
    .auto_rst(adc_auto_reset_sync),
    .locked(locked),
    .sclk_i(adc_sclk_int),
    .sdi(ADC_SDO_C),
    .cs_n(ADC_CS_N_C),
    .sclk(ADC_SCLK_C),
    .sdo(ADC_SDI_C),
    .adc_rst(ADC_RST),
    .channel_enable_count (adc_count),
    .ch1_data(ch_data[0]),
    .ch2_data(ch_data[1]),
    .ch3_data(ch_data[2]),
    .ch4_data(ch_data[3]),
    .ch5_data(ch_data[4]),
    .ch6_data(ch_data[5]),
    .ch7_data(ch_data[6]),
    .ch8_data(ch_data[7]),
    .data_valid(data_valid)
);

  dac_controller dac_controller_inst (
    .rst(dac_rst_sync),
    .locked(locked),
    .cs_n(DAC_CS_N_C),
    .sclk_i(dac_sclk_int),
    .sclk(DAC_SCLK_C),
    .sdo(DAC_SDI_C),
    .sdi(DAC_SDO_C),
    .ch1_data(ch1_data_dac),
    .ch2_data(ch2_data_dac),
    .ch3_data(ch3_data_dac),
    .ch4_data(ch4_data_dac),
    .ch5_data(ch5_data_dac),
    .ch6_data(ch6_data_dac),
    .ch7_data(ch7_data_dac),
    .ch8_data(ch8_data_dac),
    .data_rdy(dac_en)
  );

// The data of this FIFO is formatted as such:
// 31:16 - channel number
// 15: 0 - channel data
 fifo_generator_0 adc_fifo (
  .srst(1'b0),                // input wire srst
  .wr_clk(adc_sclk_int),            // input wire wr_clk
  .rd_clk(okClk),            // input wire rd_clk
  .din({8'd0, data_valid, ch_data[data_valid-1]}), // input wire [31 : 0] din
  .wr_en({|data_valid & !full}),              // input wire wr_en
  .rd_en(poa0_ep_read),              // input wire rd_en
  .dout(poa0_ep_datain),                // output wire [31 : 0] dout
  .full(full),                // output wire full
  .empty(),              // output wire empty
  .wr_rst_busy(),  // output wire wr_rst_busy
  .rd_rst_busy()  // output wire rd_rst_busy
);

endmodule
`default_nettype wire

//------------------------------------------------------------------------
// sensor.v
//
// This top level module contains glue logic to connect the peripherals
// available on the SYZYGY POD-SENSOR board to the FrontPanel interface
// on the XEM8320.                
//
// Clocking setup:
// + 100.8MHz okClk
//
// FrontPanel Endpoint Usage:
//
// WireIn     0x00     0 - RESET
//                     1 - Disable GNSS Antenna ('1' = disable, '0' = enable)
//            0x01  7: 0 - I2C Data In
//            0x02  7: 0 - HTS221 SPI Data In
//                 14: 8 - HTS221 SPI Reg Addr
//                    15 - HTS221 SPI R/W
//            0x03  7: 0 - LPS22HB SPI Data In
//                 14: 8 - LPS22HB SPI Reg Addr
//                    15 - LPS22HB SPI R/W
//            0x04  7: 0 - LSM9DS1_AG SPI Data In
//                 14: 8 - LSM9DS1_AG SPI Reg Addr
//                    15 - LSM9DS1_AG SPI R/W
//            0x05  7: 0 - LSM9DS1_M SPI Data In
//                 14: 8 - LSM9DS1_M SPI Reg Addr
//                    15 - LSM9DS1_M SPI R/W
//            0x06  7: 0 - GNSS UART Tx Data
//
// TriggerIn  0x40     0 - I2C Start
//                     1 - I2C Mem Start
//                     2 - I2C Mem Write
//                     3 - I2C Mem Read
//            0x41     0 - UART Tx Send Byte
//            0x42     0 - HTS221 SPI Send
//                     1 - LPS22HB SPI Send
//                     2 - LSM9DS1_AG SPI Send
//                     3 - LSM9DS1_M SPI Send
//
// WireOut    0x20  7: 0 - I2C Data Out
//            0x22 11: 0 - UART Rx FIFO Data Count
//                    12 - UART Tx Done
//            0x23  7: 0 - HTS221 SPI Data Out
//                     8 - HTS221 SPI Done
//            0x24  7: 0 - LPS22HB SPI Data Out
//                     8 - LPS22HB SPI Done
//            0x25  7: 0 - LSM9DS1_AG SPI Data Out
//                     8 - LSM9DS1_AG SPI Done
//            0x26  7: 0 - LSM9DS1_M SPI Data Out
//                     8 - LSM9DS1_M SPI Done
//
// TriggerOut 0x60     0 - I2C Done
//
// PipeOut    0xA0       - UART Rx FIFO Data Output
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
// 
//------------------------------------------------------------------------

`default_nettype none
`timescale 1ns / 1ps

module pod_sensor(
	input  wire [4:0]   okUH,
	output wire [2:0]   okHU,
	inout  wire [31:0]  okUHU,
	inout  wire         okAA,
	
	// Common
	output wire         spi_clk,
	
	// GNSS
	inout  wire         cam_m8q_spi_cs_n,
	input  wire         cam_m8q_extint,
	input  wire         cam_m8q_timepulse,
	output wire         cam_m8q_d_sel,
	output wire         cam_m8q_safeboot_n,
	input  wire         cam_m8q_uart_txd_spi_miso,
	output wire         cam_m8q_uart_rxd_spi_mosi,
	output wire         gnss_ext_ant_en,
	
	// Humidity + temperature
	output wire         hts221_cs,
	input  wire         hts221_drdy,
	inout  wire         hts221_spi_sdi_sdo,
	
	// Accel + Gyro + Magnetometer
	output wire         lsm9ds1_den_ag,
	input  wire         lsm9ds1_int2_ag,
	input  wire         lsm9ds1_int1_ag,
	input  wire         lsm9ds1_int_m,
	output wire         lsm9ds1_cs_m,
	input  wire         lsm9ds1_drdy_m,
	output wire         lsm9ds1_cs_ag,
	input  wire         lsm9ds1_spi_sdo_m,
	input  wire         lsm9ds1_spi_sdo_ag,
	output wire         lsm9ds1_spi_sdi_sdo,
	
	// Pressure
	output wire         lps22hb_spi_sdi_sdo,
	input  wire         lps22hb_spi_sdo,
	input  wire         lps22hb_int_drdy,
	output wire         lps22hb_cs,
	
	// Ambient Light + Proximity
	inout  wire         si1153_scl,
	inout  wire         si1153_sda,
	input  wire         si1153_int

	);

// Target interface bus:
wire         okClk;
wire         reset;
wire [112:0] okHE;
wire [64:0]  okEH;

// Endpoint connections:
wire [31:0]  ep00wire, ep01wire, ep02wire, ep03wire, ep04wire, ep05wire, ep06wire;
wire [31:0]  ep20wire, ep22wire, ep23wire, ep24wire, ep25wire, ep26wire;
wire [31:0]  ti40_okClk, ti41_okClk, ti42_okClk;
wire [31:0]  to60_okClk;
wire [31:0]  epA0pipe;
wire         epA0read;

// Internal hookup
wire [7:0]   uart_rx_data;
wire         uart_rx_valid;

wire i2c_scl, i2c_sda, i2c_dout, i2c_sdat_oen, i2c_sclk_oen;

wire spi_clk_hts221, spi_clk_lsm9ds1_ag, spi_clk_lsm9ds1_m, spi_clk_lps22hb;
wire hts221_sdi, hts221_sdo, hts221_sdi_sdo_dir;
wire lsm9ds1_spi_sdi_sdo_ag, lsm9ds1_spi_sdi_sdo_m;

// Basic pin assignments
assign lsm9ds1_den_ag = 1'b1;      // Enable data for LSM9DS1
assign cam_m8q_spi_cs_n = 1'bZ;    // Release SDA for GNSS
assign cam_m8q_d_sel = 1'b1;       // Hold D_SEL high for GNSS
assign cam_m8q_safeboot_n = 1'bZ;  // Safeboot pin is disconnected by default

assign reset = ep00wire[0];
assign gnss_ext_ant_en = ep00wire[1]; // 1 = Internal antenna, 0 = External


uart_rx #(
	.CLK_DIV (10500)
) uart0rx (
	.clk           (okClk),
	.reset         (reset),
	.uart_rx       (cam_m8q_uart_txd_spi_miso),
	.uart_data     (uart_rx_data),
	.byte_received (uart_rx_valid)
);

uart_tx #(
	.CLK_DIV (10500)
) uart0tx (
	.clk       (okClk),
	.reset     (reset),
	.uart_tx   (cam_m8q_uart_rxd_spi_mosi),
	.uart_data (ep06wire[7:0]),
	.uart_done (ep22wire[12]),
	.send_byte (ti41_okClk[0])
);

fifo_w8_r32 uart_rx_fifo (
	.clk           (okClk),
	.srst          (reset),
	.din           (uart_rx_data),
	.wr_en         (uart_rx_valid),
	.rd_en         (epA0read),
	.dout          (epA0pipe),
	.data_count (ep22wire[11:0]),
	.full          (),
	.empty         ()
);

// SPI Connections
assign spi_clk = spi_clk_hts221 & spi_clk_lps22hb & spi_clk_lsm9ds1_ag & spi_clk_lsm9ds1_m;

assign hts221_spi_sdi_sdo = (hts221_sdi_sdo_dir) ? (hts221_sdo) : (1'bZ);
assign hts221_sdi         = hts221_spi_sdi_sdo;

spi_control #(
	.DIVIDE_COUNT (32'd100)
) hts221_spi (
	.clk           (okClk),
	.reset         (reset),
	.sclk          (spi_clk_hts221),
	.miso          (hts221_sdi),
	.mosi          (hts221_sdo),
	.miso_mosi_dir (hts221_sdi_sdo_dir),
	.cs_n          (hts221_cs),
	
	.spi_reg      (ep02wire[14:8]),
	.spi_data_in  (ep02wire[7:0]),
	.spi_data_out (ep23wire[7:0]),
	.spi_send     (ti42_okClk[0]),
	.spi_done     (ep23wire[8]),
	.spi_rw       (ep02wire[15])
);

spi_control #(
	.DIVIDE_COUNT (32'd100)
) lps22hb_spi (
	.clk           (okClk),
	.reset         (reset),
	.sclk          (spi_clk_lps22hb),
	.miso          (lps22hb_spi_sdo),
	.mosi          (lps22hb_spi_sdi_sdo),
	.miso_mosi_dir (),
	.cs_n          (lps22hb_cs),
	
	.spi_reg      (ep03wire[14:8]),
	.spi_data_in  (ep03wire[7:0]),
	.spi_data_out (ep24wire[7:0]),
	.spi_send     (ti42_okClk[1]),
	.spi_done     (ep24wire[8]),
	.spi_rw       (ep03wire[15])
);

assign lsm9ds1_spi_sdi_sdo = (lsm9ds1_spi_sdi_sdo_ag | lsm9ds1_cs_ag) & (lsm9ds1_spi_sdi_sdo_m | lsm9ds1_cs_m);

spi_control #(
	.DIVIDE_COUNT (32'd100)
) lsm9ds1_ag_spi (
	.clk           (okClk),
	.reset         (reset),
	.sclk          (spi_clk_lsm9ds1_ag),
	.miso          (lsm9ds1_spi_sdo_ag),
	.mosi          (lsm9ds1_spi_sdi_sdo_ag),
	.miso_mosi_dir (),
	.cs_n          (lsm9ds1_cs_ag),
	
	.spi_reg      (ep04wire[14:8]),
	.spi_data_in  (ep04wire[7:0]),
	.spi_data_out (ep25wire[7:0]),
	.spi_send     (ti42_okClk[2]),
	.spi_done     (ep25wire[8]),
	.spi_rw       (ep04wire[15])
);

spi_control #(
	.DIVIDE_COUNT (32'd100)
) lsm9ds1_m_spi (
	.clk           (okClk),
	.reset         (reset),
	.sclk          (spi_clk_lsm9ds1_m),
	.miso          (lsm9ds1_spi_sdo_m),
	.mosi          (lsm9ds1_spi_sdi_sdo_m),
	.miso_mosi_dir (),
	.cs_n          (lsm9ds1_cs_m),
	
	.spi_reg      (ep05wire[14:8]),
	.spi_data_in  (ep05wire[7:0]),
	.spi_data_out (ep26wire[7:0]),
	.spi_send     (ti42_okClk[3]),
	.spi_done     (ep26wire[8]),
	.spi_rw       (ep05wire[15])
);

// I2C Connections
i2cController #(
	.CLOCK_DIVIDER (16'h114)
) i2c0 (
	.clk   (okClk),
	.reset (reset),
	.start (ti40_okClk[0]),
	.done  (to60_okClk[0]),
	
	.memclk   (okClk),
	.memstart (ti40_okClk[1]),
	.memwrite (ti40_okClk[2]),
	.memread  (ti40_okClk[3]),
	.memdin   (ep01wire[7:0]),
	.memdout  (ep20wire[7:0]),
	
	.i2c_sclk (si1153_scl),
	.i2c_sdat (si1153_sda)
);

// Instantiate the okHost and connect endpoints.
wire [65*8-1:0]  okEHx;
okHost okHI(
	.okUH(okUH),
	.okHU(okHU),
	.okUHU(okUHU),
	.okAA(okAA),
	.okClk(okClk),
	.okHE(okHE), 
	.okEH(okEH)
);

okWireOR # (.N(8)) wireOR (okEH, okEHx);

okWireIn     ep00 (.okHE(okHE),                             .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn     ep01 (.okHE(okHE),                             .ep_addr(8'h01), .ep_dataout(ep01wire));
okWireIn     ep02 (.okHE(okHE),                             .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireIn     ep03 (.okHE(okHE),                             .ep_addr(8'h03), .ep_dataout(ep03wire));
okWireIn     ep04 (.okHE(okHE),                             .ep_addr(8'h04), .ep_dataout(ep04wire));
okWireIn     ep05 (.okHE(okHE),                             .ep_addr(8'h05), .ep_dataout(ep05wire));
okWireIn     ep06 (.okHE(okHE),                             .ep_addr(8'h06), .ep_dataout(ep06wire));
okWireOut    ep20 (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'h20), .ep_datain(ep20wire));
okWireOut    ep22 (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]), .ep_addr(8'h22), .ep_datain(ep22wire));
okWireOut    ep23 (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]), .ep_addr(8'h23), .ep_datain(ep23wire));
okWireOut    ep24 (.okHE(okHE), .okEH(okEHx[ 3*65 +: 65 ]), .ep_addr(8'h24), .ep_datain(ep24wire));
okWireOut    ep25 (.okHE(okHE), .okEH(okEHx[ 4*65 +: 65 ]), .ep_addr(8'h25), .ep_datain(ep25wire));
okWireOut    ep26 (.okHE(okHE), .okEH(okEHx[ 5*65 +: 65 ]), .ep_addr(8'h26), .ep_datain(ep26wire));
okTriggerIn  ti40 (.okHE(okHE),                             .ep_addr(8'h40), .ep_clk(okClk), .ep_trigger(ti40_okClk));
okTriggerIn  ti41 (.okHE(okHE),                             .ep_addr(8'h41), .ep_clk(okClk), .ep_trigger(ti41_okClk));
okTriggerIn  ti42 (.okHE(okHE),                             .ep_addr(8'h42), .ep_clk(okClk), .ep_trigger(ti42_okClk));
okTriggerOut to60 (.okHE(okHE), .okEH(okEHx[ 6*65 +: 65 ]), .ep_addr(8'h60), .ep_clk(okClk), .ep_trigger(to60_okClk));
okPipeOut    poA0 (.okHE(okHE), .okEH(okEHx[ 7*65 +: 65 ]), .ep_addr(8'hA0), .ep_datain(epA0pipe), .ep_read(epA0read));

endmodule
`default_nettype wire

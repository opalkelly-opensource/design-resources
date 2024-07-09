`timescale 1ns / 1ps
//------------------------------------------------------------------------
// fp_slicer.v
//
// A simple piece of HDL that combines various control signals into one
// HDL module.
// 
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

module fp_slicer(
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:register_bridge:1.0 register_bridge EP_WRITE" *)
    input  wire        regbridge_ep_write,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:register_bridge:1.0 register_bridge EP_READ" *)
    input  wire        regbridge_ep_read,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:register_bridge:1.0 register_bridge EP_ADDRESS" *)
    input  wire [31:0] regbridge_ep_address,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:register_bridge:1.0 register_bridge EP_DATAOUT" *)
    input  wire [31:0] regbridge_ep_dataout,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:register_bridge:1.0 register_bridge EP_DATAIN" *)
    output wire [31:0] regbridge_ep_datain,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:register_bridge:1.0 register_bridge_ifft EP_WRITE" *)
    output  wire        ifft_regbridge_ep_write,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:register_bridge:1.0 register_bridge_ifft EP_READ" *)
    output  wire        ifft_regbridge_ep_read,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:register_bridge:1.0 register_bridge_ifft EP_ADDRESS" *)
    output  wire [31:0] ifft_regbridge_ep_address,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:register_bridge:1.0 register_bridge_ifft EP_DATAOUT" *)
    output  wire [31:0] ifft_regbridge_ep_dataout,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:register_bridge:1.0 register_bridge_ifft EP_DATAIN" *)
    input wire [31:0] ifft_regbridge_ep_datain,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wirein:1.0 wirein00 EP_DATAOUT" *)
    input  wire [31:0] wi00_ep_dataout,
   
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wireout:1.0 wireout20_status EP_DATAIN" *)
    output wire [31:0] wo20_ep_datain_status_signals,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin40_resets EP_TRIGGER" *)
    input  wire [31:0] ti40_ep_trigger,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin40_resets EP_CLK" *)
    output wire        ti40_ep_clk,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin41_resets EP_TRIGGER" *)
    input  wire [31:0] ti41_ep_trigger,
   
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin41_resets EP_CLK" *)
    output wire        ti41_ep_clk,
    
    output wire wi00_control_1_ifft_reset,
    output wire ti41_resets_0_clk_reset,
    output wire ti40_resets_1_ifft_ctrl_start,
    output wire ti40_resets_2_fft_ctrl_start,
    output wire wi00_control_0_dis_out,
    
    input wire adc_fifo_prog_full,
    
    input wire ifft_clk,
    input wire okClk,
    input wire dac_ready,
    input wire locked,
    
    input wire fft_tx_fifo_prog_empty,
    input wire fft_rx_fifo_prog_full
    
    );
    
    assign ifft_regbridge_ep_write = regbridge_ep_write;
    assign ifft_regbridge_ep_read = regbridge_ep_read;
    assign ifft_regbridge_ep_address = regbridge_ep_address;
    assign ifft_regbridge_ep_dataout = regbridge_ep_dataout;
    assign regbridge_ep_datain = ifft_regbridge_ep_datain;
    
    assign ti40_ep_clk = ifft_clk;
    assign ti41_ep_clk = ifft_clk;
    assign wo20_ep_datain_status_signals = {27'd0, fft_tx_fifo_prog_empty, fft_rx_fifo_prog_full, adc_fifo_prog_full, dac_ready, locked};
    assign wi00_control_0_dis_out = wi00_ep_dataout[0];
    assign wi00_control_1_ifft_reset = wi00_ep_dataout[1];
    assign ti41_resets_0_clk_reset = ti41_ep_trigger[0];
    assign ti40_resets_1_ifft_ctrl_start = ti40_ep_trigger[1];
    assign ti40_resets_2_fft_ctrl_start = ti40_ep_trigger[2];
    

endmodule

`default_nettype wire

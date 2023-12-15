// ----------------------------------------------------------------------------------------
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
// ----------------------------------------------------------------------------------------
// Description:
//     Interface module for FrontPanel to AXI-Lite controller for use within
//     the AMD IPI block designer. This module creates interfaces recognizable
//     to the AMD IPI block designer, allowing direct connection to the FrontPanel
//     Subsystem Vivado IP Core. The primary function of this module is to provide
//     a reset mechanism to the AXI system, initiated from the FrontPanel. This 
//     module acts as a wrapper for AMD's Processor System Reset Module IP, which 
//     offers customized resets for the entire processor system, including the 
//     interconnect and peripherals. It adheres to the reset guidelines outlined 
//     in AMD's AXI Reference Guide (UG1037), with a key guideline being that a 
//     reset asserted for 16 cycles of the slowest AXI clock typically provides a 
//     sufficient reset pulse width for Xilinx IP.
// -----------------------------------------------------------------------------

module axi_reset_iwrap(

    (* X_INTERFACE_INFO = "opalkelly.com:interface:wirein:1.0 wirein00_axi_reset EP_DATAOUT" *)
    input  wire [31:0] wi00_ep_dataout_axi_reset,

    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET peripheral_aresetn" *)
    input  wire sync_clk,
    
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0  peripheral_aresetn  RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    output wire peripheral_aresetn
);

wire aux_reset_in;

assign aux_reset_in = wi00_ep_dataout_axi_reset[0];

proc_sys_reset_0 proc_sys_reset_0_inst (
  .slowest_sync_clk(sync_clk),                  // input wire slowest_sync_clk
  .ext_reset_in(1'b0),                          // input wire ext_reset_in
  .aux_reset_in(aux_reset_in),                  // input wire aux_reset_in
  .mb_debug_sys_rst(1'b0),                      // input wire mb_debug_sys_rst
  .dcm_locked(1'b1),                            // input wire dcm_locked
  .mb_reset(),                                  // output wire mb_reset
  .bus_struct_reset(),                          // output wire [0 : 0] bus_struct_reset
  .peripheral_reset(),                          // output wire [0 : 0] peripheral_reset
  .interconnect_aresetn(),                      // output wire [0 : 0] interconnect_aresetn
  .peripheral_aresetn(peripheral_aresetn)       // output wire [0 : 0] peripheral_aresetn
);

endmodule

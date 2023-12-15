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
//     Subsystem Vivado IP Core.
//
// Features:
//     - Provides top-level ports as Interfaces recognizable by the AMD IPI block designer.
//     - Adheres to the "Naming Convention Benefits" from Opal Kelly's FrontPanel SDK,
//       with endpoint addresses embedded directly in the interface names. This approach
//       not only makes integration with the FrontPanel Subsystem Vivado IP Core intuitive
//       but also simplifies the process of defining the API AXI-Lite object in software,
//       which requires endpoint addresses in the object constructor.
//       Reference: https://docs.opalkelly.com/fpsdk/frontpanel-hdl/vivado-ip-core/discussion/naming-convention-benefits/
//     - Address visibility at the top-level IPI block design ensures seamless software
//       integration with the API.
//
// Important Note:
//     This file becomes especially relevant when aiming to use the "FrontPanel to AXI-Lite 
//     controller" in the AMD IPI block designer.
// -----------------------------------------------------------------------------
module fp_to_axil_iwrap(
    input wire          aclk,
    input wire          aresetn,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wirein:1.0 wirein1d_fp_to_axil_addr EP_DATAOUT" *)
    input  wire [31:0] wi1d_ep_dataout_fp_to_axil_addr,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wirein:1.0 wirein1e_fp_to_axil_data EP_DATAOUT" *)
    input  wire [31:0] wi1e_ep_dataout_fp_to_axil_data,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wirein:1.0 wirein1f_fp_to_axil_timeout EP_DATAOUT" *)
    input  wire [31:0] wi1f_ep_dataout_fp_to_axil_timeout,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wireout:1.0 wireout3e_fp_to_axil_data EP_DATAIN" *)
    output wire [31:0] wo3e_ep_datain_fp_to_axil_data,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wireout:1.0 wireout3f_fp_to_axil_status EP_DATAIN" *)
    output wire [31:0] wo3f_ep_datain_fp_to_axil_status,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin5f_fp_to_axil_operation EP_TRIGGER" *)
    input  wire [31:0] ti5f_ep_trigger_fp_to_axil_operation,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin5f_fp_to_axil_operation EP_CLK" *)
    output wire        ti5f_ep_clk_fp_to_axil_operation,
    
    /*
     * AXI lite master interface
     */    
    output wire [31:0]            m_axil_awaddr,
    output wire                   m_axil_awvalid,
    input  wire                   m_axil_awready,
    output wire [31:0]            m_axil_wdata,
    output wire [3:0]             m_axil_wstrb,
    output wire                   m_axil_wvalid,
    input  wire                   m_axil_wready,
    input  wire [1:0]             m_axil_bresp,
    input  wire                   m_axil_bvalid,
    output wire                   m_axil_bready,
    output wire [31:0]            m_axil_araddr,
    output wire                   m_axil_arvalid,
    input  wire                   m_axil_arready,
    input  wire [31:0]            m_axil_rdata,
    input  wire [1:0]             m_axil_rresp,
    input  wire                   m_axil_rvalid,
    output wire                   m_axil_rready
);

// Instantiate fp_to_axil module
fp_to_axil fp_to_axil_i (
    .aclk(aclk),
    .aresetn(aresetn),

    // FP slave interface
    .fp_to_axil_address(wi1d_ep_dataout_fp_to_axil_addr),
    .fp_to_axil_data_out(wi1e_ep_dataout_fp_to_axil_data),
    .fp_to_axil_data_in(wo3e_ep_datain_fp_to_axil_data),
    .fp_to_axil_trigger_in_operation(ti5f_ep_trigger_fp_to_axil_operation),
    .fp_to_axil_trigger_in_ep_clk_operation(ti5f_ep_clk_fp_to_axil_operation),
    .fp_to_axil_status_out(wo3f_ep_datain_fp_to_axil_status),
    .fp_to_axil_timeout_value(wi1f_ep_dataout_fp_to_axil_timeout),

    // AXI lite master interface
    .m_axil_awaddr(m_axil_awaddr),
    .m_axil_awvalid(m_axil_awvalid),
    .m_axil_awready(m_axil_awready),
    .m_axil_wdata(m_axil_wdata),
    .m_axil_wstrb(m_axil_wstrb),
    .m_axil_wvalid(m_axil_wvalid),
    .m_axil_wready(m_axil_wready),
    .m_axil_bresp(m_axil_bresp),
    .m_axil_bvalid(m_axil_bvalid),
    .m_axil_bready(m_axil_bready),
    .m_axil_araddr(m_axil_araddr),
    .m_axil_arvalid(m_axil_arvalid),
    .m_axil_arready(m_axil_arready),
    .m_axil_rdata(m_axil_rdata),
    .m_axil_rresp(m_axil_rresp),
    .m_axil_rvalid(m_axil_rvalid),
    .m_axil_rready(m_axil_rready)
); 

endmodule

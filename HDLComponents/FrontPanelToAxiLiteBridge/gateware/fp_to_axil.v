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
//
// Description:   Bridge between FrontPanel endpoints and an AXI-Lite master interface.
//
//                This module facilitates the communication between the software 
//                application/FrontPanel Subsystem Vivado IP Core (acting as the Master)
//                and the AXI-Lite master interface. The FrontPanel endpoints are viewed
//                as the slave interface of this module, while the AXI-Lite master interface
//                is obviously the master and communicates with other AXI-Lite slave peripherals.

`timescale 1ns / 1ps
`default_nettype none

module fp_to_axil (
    input wire                    aclk,
    input wire                    aresetn,
    
    /*
     * FP slave interface
     */
    input  wire [31:0] fp_to_axil_address,
    input  wire [31:0] fp_to_axil_data_out,
    output wire [31:0] fp_to_axil_data_in,
    
    input  wire [31:0] fp_to_axil_trigger_in_operation,
    output  wire       fp_to_axil_trigger_in_ep_clk_operation,
    output wire [31:0] fp_to_axil_status_out,
    input wire  [31:0] fp_to_axil_timeout_value,
    
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

localparam [1:0]
    STATE_IDLE = 2'd0,
    STATE_READ = 2'd1,
    STATE_WRITE = 2'd2;

reg [2:0] state_reg = STATE_IDLE, state_next;

reg [31:0] addr_reg = 32'd0, addr_next;

reg [31:0] response_reg = 32'd0, response_next;
reg [31:0] data_in_reg = 32'd0, data_in_next;
reg [31:0] m_axil_wdata_reg = 32'd0, m_axil_wdata_next;

reg m_axil_awvalid_reg = 1'b0, m_axil_awvalid_next;
reg [3:0] m_axil_wstrb_reg = 4'b000, m_axil_wstrb_next;
reg m_axil_wvalid_reg = 1'b0, m_axil_wvalid_next;
reg m_axil_bready_reg = 1'b0, m_axil_bready_next;
reg m_axil_arvalid_reg = 1'b0, m_axil_arvalid_next;
reg m_axil_rready_reg = 1'b0, m_axil_rready_next;

reg busy_reg = 1'b0;

assign fp_to_axil_trigger_in_ep_clk_operation = aclk;

assign m_axil_awaddr = addr_reg;
assign m_axil_awvalid = m_axil_awvalid_reg;
assign m_axil_wdata = m_axil_wdata_reg;
assign m_axil_wstrb = m_axil_wstrb_reg;
assign m_axil_wvalid = m_axil_wvalid_reg;
assign m_axil_bready = m_axil_bready_reg;
assign m_axil_araddr = addr_reg;
assign m_axil_arvalid = m_axil_arvalid_reg;
assign m_axil_rready = m_axil_rready_reg;

assign fp_to_axil_data_in = data_in_reg;
assign fp_to_axil_status_out = {29'd0, response_reg, busy_reg};

reg [31:0] timeout_reg = 32'd0, timeout_next;
reg [31:0] timeout_counter = 32'd0;

reg rst_timeout_counter;
always @(posedge aclk) begin
    if (rst_timeout_counter) begin
        timeout_counter <= 32'd0;
    end else begin
        timeout_counter <= timeout_counter + 32'd1;
    end
    
end

// AXI-Lite Command State Machine
// This state machine handles both AXI-Lite read and write operations.
// 
// - In the IDLE state, the machine waits for a trigger to initiate a read or write.
// 
// - For write operations, the machine moves from IDLE to the WRITE state.
//   In this state, it waits for the write acknowledgment. If an acknowledgment is received
//   or a timeout occurs, the state machine returns to IDLE. The timeout is set to prevent 
//   the machine from getting stuck if there's no slave at the transaction address.
//
// - For read operations, the machine moves from IDLE to the READ state.
//   Here, it waits for the read data to become available. Once the data is available or
//   a timeout occurs, the machine goes back to IDLE. Similar to the write operation, the 
//   timeout ensures that the machine doesn't get stuck waiting indefinitely for a 
//   response in case of an absent slave.
always @* begin
    state_next = state_reg;

    addr_next = addr_reg;
    
    response_next = response_reg;
    data_in_next = data_in_reg;
    m_axil_wdata_next = m_axil_wdata_reg;

    m_axil_awvalid_next = m_axil_awvalid_reg && !m_axil_awready;
    m_axil_wstrb_next = m_axil_wstrb_reg & {4{!m_axil_wready}};
    m_axil_wvalid_next = m_axil_wvalid_reg && !m_axil_wready;
    m_axil_bready_next = 1'b0;
    m_axil_arvalid_next = m_axil_arvalid_reg && !m_axil_arready;
    m_axil_rready_next = 1'b0;
    
    timeout_next = timeout_reg;
    rst_timeout_counter = 1'b0;
    
    case (state_reg)
        STATE_IDLE: begin
            if (fp_to_axil_trigger_in_operation[0]) begin
                // write
                state_next = STATE_WRITE;
                rst_timeout_counter = 1'b1;
                timeout_next = fp_to_axil_timeout_value;
                
                addr_next = fp_to_axil_address;
                m_axil_wdata_next = fp_to_axil_data_out;
                m_axil_wstrb_next = 4'b1111;
                
                m_axil_awvalid_next = 1'b1;
                m_axil_wvalid_next = 1'b1;
                m_axil_bready_next = 1'b1;
            end else if (fp_to_axil_trigger_in_operation[1]) begin
                // read
                state_next = STATE_READ;
                rst_timeout_counter = 1'b1;
                timeout_next = fp_to_axil_timeout_value;
                
                addr_next = fp_to_axil_address;
                
                m_axil_arvalid_next = 1'b1;
                m_axil_rready_next = 1'b1;
            end
        end
        STATE_READ: begin
            // wait for data
            m_axil_rready_next = 1'b1;

            if (m_axil_rready && m_axil_rvalid) begin
                // read cycle complete, store result
                data_in_next = m_axil_rdata;
                response_next = m_axil_rresp;
                state_next = STATE_IDLE;
            end else if (timeout_reg != 0 && (timeout_counter >=  timeout_reg)) begin
                // If timeout is zero we wait indefinitely for a response
                response_next = 3'b100;
                state_next = STATE_IDLE;  // revert to idle if timeout reached
            end
        end

        STATE_WRITE: begin
            // wait for write completion
            m_axil_bready_next = 1'b1;

            if (m_axil_bready && m_axil_bvalid) begin
                // end of write operation
                response_next = m_axil_bresp;
                state_next = STATE_IDLE;
            end else if (timeout_reg != 0 && (timeout_counter >=  timeout_reg)) begin
                // If timeout is zero we wait indefinitely for a response
                response_next = 3'b100;
                state_next = STATE_IDLE;  // revert to idle if timeout reached
            end
        end

    endcase
end

// Sequential Logic for AXI-Lite Command Controller
// 
// The coding style adopted for this controller involves using a combinational always block 
// (as shown above this block) to define all the combinational logic. Within that block, 
// the "_next" postfix is used to signify the next value of a state or signal that will be 
// loaded on the next clock edge. For any net that is to be sequential, we use two postfixed 
// names: "_reg" for the current state or value, and "_next" for its next state or value.
//
// In this always block, we utilize the rising edge of the clock signal (posedge clk) to 
// perform sequential updates. On a reset condition (signified by ~aresetn), all 
// the "_reg" postfixed signals are set to their initial values. Otherwise, on every 
// clock cycle, the "_reg" postfixed signals are updated with their corresponding "_next" values,
// which were calculated in the combinational block above.
always @(posedge aclk) begin
    if (~aresetn) begin
        state_reg <= STATE_IDLE;
        
        addr_reg <= 32'd0;
        
        response_reg <= 2'b00;
        data_in_reg <= 32'd0;
        m_axil_wdata_reg <= 32'd0;
        
        m_axil_awvalid_reg <= 1'b0;
        m_axil_wstrb_reg <= 4'b0000;
        m_axil_wvalid_reg <= 1'b0;
        m_axil_bready_reg <= 1'b0;
        m_axil_arvalid_reg <= 1'b0;
        m_axil_rready_reg <= 1'b0;
        
        busy_reg <= 1'b0;
        
    end else begin
        state_reg <= state_next;

        addr_reg <= addr_next;
        
        response_reg <= response_next;
        data_in_reg <= data_in_next;
        m_axil_wdata_reg <= m_axil_wdata_next;

        m_axil_awvalid_reg <= m_axil_awvalid_next;
        m_axil_wstrb_reg <= m_axil_wstrb_next;
        m_axil_wvalid_reg <= m_axil_wvalid_next;
        m_axil_bready_reg <= m_axil_bready_next;
        m_axil_arvalid_reg <= m_axil_arvalid_next;
        m_axil_rready_reg <= m_axil_rready_next;

        busy_reg <= state_next != STATE_IDLE;
        
        timeout_reg <= timeout_next;
    end
end

endmodule
`default_nettype wire

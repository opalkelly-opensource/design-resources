`timescale 1ns / 1ps
//------------------------------------------------------------------------
// ifft_controller.v
//
// Handles interfacing to the Vitis HLS IFFT IP. Purpose is to send
// frequency bin data to the IFFT core that is stored in BRAM. The frequency
// bins are set using FrontPanelAPI register bridge. Even BRAM addresses 
// make up the real component, and odd BRAM addresses make up the imaginary
// component.
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

module ifft_controller(
    input  wire okClk,
    
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
    
    input wire [9:0] ifft_address_in,
    input wire ifft_ce_in,
    input wire ifft_ready, 
    input wire ifft_done,
    input wire ifft_idle,
    input wire ifft_clk,
    input wire ifft_clk_locked,
    input wire start, 
    
    input wire reset,
    
    output wire ifft_start,
    output wire ifft_reset,
    output wire [43:0] ifft_input_data
    );
  
  wire [63:0] bram_data;
  wire rsta_busy, rstb_busy;
  wire bram_rst_busy;
  reg ifft_start_r = 1'b0;
  reg ifft_reset_r = 1'b0;
  reg [3:0] ifft_reset_counter = 4'd0;
  reg [10:0] ifft_ready_counter = 11'd0;
  
  assign ifft_start = ifft_start_r;
  assign ifft_reset = ifft_reset_r;
  assign ifft_input_data = {bram_data[53:32], bram_data[21:0]}; // bram_data[19:0] is the real component value
  assign bram_rst_busy = rsta_busy | rstb_busy;                 // bram_data[51:32] is the imaginary component value
    
  always @(posedge ifft_clk) begin
    if (reset || !ifft_clk_locked) begin // stay in reset if clock not locked or reset asserted
        ifft_start_r <= 1'b0;
        ifft_reset_r <= 1'b1;
        ifft_reset_counter <= 4'd0;
        ifft_ready_counter <= 11'd0;
    end else if (ifft_reset_r) begin // reset counter
        if (ifft_reset_counter != 4'd14) begin // assert reset for 14 cycles as shown in Vitis HLS test bench
            ifft_reset_counter <= ifft_reset_counter + 1'd1;
        end else begin
            ifft_reset_r <= 1'b0;
        end
    end else if (start && !bram_rst_busy && ifft_idle && !ifft_start_r) begin // initate ifft transaction
        ifft_start_r <= 1'b1;
        ifft_ready_counter <= 11'd0;
    end else if (ifft_start_r) begin // keep ifft_start asserted for 256 + 1 cycles for BRAM latency
        if (ifft_ready_counter != 11'd1024) begin
            ifft_ready_counter <= ifft_ready_counter + 1'b1;
        end else begin
            ifft_start_r <= 1'b0;
        end
    end
  end
  
  // The ifft_bram has a 32-bit data width on its port A, and it is connected to the FrontPanel Register Bridge endpoint, which
  // also has a 32-bit data width. The frequency vector has a width of 40 bits, with 20 bits reserved for the real portion and 20
  // bits for the imaginary portion. To accommodate this, we store the 20-bit real value at one address location and the 20-bit
  // imaginary value at the next address location, since 40 bits exceeds the 32-bit data capacity of a single address location. 
  //
  // The data width of output port B is 64 bits, and it concatenates the real and imaginary address locations into a single address
  // at port B. Each clock cycle, the IFFT core utilizes this address to access data, as it necessitates the complete 40-bit frequency
  // vector to be accessible. However, the 40-bit frequency vector is partitioned at 32-bit boundaries and is not contiguous on port B's
  // 64-bit data output. The real and imaginary bit vector locations that are valid are obtained by splicing them from port B's 64-bit
  // data output, as demonstrated in the `ifft_input_data` net assignment above.
  //
  // Refer to the following address locations of port A for the Real and imaginary components of any frequency bin N (0-255).
  //   - Frequency vector N's real component address = N * 2
  //   - Frequency vector N's imaginary component address = N * 2 + 1
  // 
  // Read Latencies
  //   - Port A read latency: 1 clk cycle, for okRegisterBridge
  //   - Port B read latency: 1 clk cycle, for the Vitis HLS core
  blk_mem_gen_0 ifft_bram(
    .clka(okClk),
    .ena({regbridge_ep_read | regbridge_ep_write}),
    .wea(regbridge_ep_write),
    .addra(regbridge_ep_address[10:0]),
    .dina(regbridge_ep_dataout),
    .douta(regbridge_ep_datain),
    .rsta(reset),
    .rsta_busy(rsta_busy),
    .rstb(reset),
    .rstb_busy(rstb_busy),
    .clkb(ifft_clk),
    .enb(ifft_ce_in),
    .web(1'b0), //unused
    .addrb(ifft_address_in),
    .dinb(1'b0), //unused
    .doutb(bram_data)
  );
    
endmodule

`default_nettype wire

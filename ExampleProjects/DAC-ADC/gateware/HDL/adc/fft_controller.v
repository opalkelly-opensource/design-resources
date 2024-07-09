`timescale 1ns / 1ps
//------------------------------------------------------------------------
// fft_controller.v
//
// Handles interfacing to the Vitis HLS fft IP. Purpose is to send
// frequency bin data to the fft core that is stored in BRAM. The frequency
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

module fft_controller(
    input  wire okClk,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:pipeout:1.0 pipeouta1 EP_DATAIN" *)
    output wire [31:0]         poa1_data_out,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:pipeout:1.0 pipeouta1 EP_READ" *)
    input  wire                poa1_ep_read,  
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:pipein:1.0 pipein80 EP_DATAOUT" *)
    input  wire [31:0] pi80_ep_dataout,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:pipein:1.0 pipein80 EP_WRITE" *)
    input  wire        pi80_ep_write,
        
    input wire [9:0] fft_address_in,
    input wire fft_ce_in,
    input wire fft_ce_out,
    input wire fft_ready, 
    input wire fft_done,
    input wire fft_idle,
    input wire fft_clk,
    input wire fft_clk_locked,
    input wire [47:0] fft_datain,
    
    input wire reset,
    input wire start,
    
    output wire fft_start,
    output wire fft_reset,
    output wire [13:0] fft_input_data,
    
    output wire fft_tx_fifo_prog_empty,
    output wire fft_rx_fifo_prog_full
    );
  
  wire [63:0] bram_data;
  wire rsta_busy, rstb_busy;
  wire [15:0] fifo_out;
  wire tx_fifo_rst_busy;
  reg fft_start_r = 1'b0;
  reg fft_reset_r = 1'b0;
  reg [3:0] fft_reset_counter = 4'd0;
  reg [10:0] fft_ready_counter = 11'd0;
   
  assign fft_start = fft_start_r;
  assign fft_reset = fft_reset_r;
  assign fft_input_data = fifo_out[13:0];

  //assign fft_input_data = fft_datain[13:0]; // bram_data[13:0] is the real component value
  assign tx_fifo_rst_busy = rsta_busy | rstb_busy;                 // bram_data[51:32] is the imaginary component value
    
  always @(posedge fft_clk) begin
    if (reset || !fft_clk_locked) begin // stay in reset if clock not locked or reset asserted
        fft_start_r <= 1'b0;
        fft_reset_r <= 1'b1;
        fft_reset_counter <= 4'd0;
        fft_ready_counter <= 11'd0;
    end else if (fft_reset_r) begin // reset counter
        if (fft_reset_counter != 4'd14) begin // assert reset for 14 cycles as shown in Vitis HLS test bench
            fft_reset_counter <= fft_reset_counter + 1'd1;
        end else begin
            fft_reset_r <= 1'b0;
        end
    end else if (start && !tx_fifo_rst_busy && fft_idle && !fft_start_r) begin // initate fft transaction
        fft_start_r <= 1'b1;
        fft_ready_counter <= 11'd0;
    end else if (fft_start_r) begin // keep fft_start asserted for 1024 + 1 cycles for BRAM latency
        if (fft_ready_counter != 11'd1024) begin
            fft_ready_counter <= fft_ready_counter + 1'b1;
        end else begin
            fft_start_r <= 1'b0;
        end
    end
  end
  
  // Note the input and output widths of 16 and 32 bits, respectively. This FIFO handles sending the 14 bit wide data from the 
  // host to the FFT using pipe 0x80. Since pipes are 32 bits wide, each pipe transaction contains two samples for the FFT. 
  // The FFT core handles the read signals, and the pipe signals handle the write signals.
  fifo_generator_1 fft_tx_fifo(
  .srst(1'b0),                // input wire srst
  .wr_clk(okClk),            // input wire wr_clk
  .rd_clk(fft_clk),            // input wire rd_clk
  .din({pi80_ep_dataout[15:0], pi80_ep_dataout[31:16]}),                  // input wire [31 : 0] din
  .wr_en(pi80_ep_write),              // input wire wr_en
  .rd_en(fft_ce_in),              // input wire rd_en
  .dout(fifo_out),                // output wire [15 : 0] dout
  .full(),                // output wire full
  .prog_empty(fft_tx_fifo_prog_empty),          // output wire prog_empty (1018). Not allowed to do prog_full at 1024.
  .empty(),              // output wire empty
  .wr_rst_busy(rsta_busy),  // output wire wr_rst_busy
  .rd_rst_busy(rstb_busy)  // output wire rd_rst_busy
);

  // Note the input and output widths of 64 and 32 bits, respectively. This FIFO handles receiving the 48 bit output data from the FFT and
  // sending it to the host via pipe A1. The FFT core handles writing, and the pipe handles reading.
  // Input:
  //        [23:0] - real component
  //        [47:24] - imaginary component
  fifo_generator_2 fft_rx_fifo(
  .srst(1'b0),                // input wire srst
  .wr_clk(fft_clk),            // input wire wr_clk
  .rd_clk(okClk),            // input wire rd_clk
  .din({16'd0, fft_datain[47:24], fft_datain[23:0]}),                  // input wire [63 : 0] din
  .wr_en(fft_ce_out),              // input wire wr_en
  .rd_en(poa1_ep_read),              // input wire rd_en
  .dout({poa1_data_out[7:0], poa1_data_out[15:8], poa1_data_out[23:16], poa1_data_out[31:24]}), // output wire [31 : 0] dout
  .full(),                // output wire full
  .prog_full(fft_rx_fifo_prog_full),          // output wire prog_full (1024)
  .empty(),              // output wire empty
  .wr_rst_busy(),  // output wire wr_rst_busy
  .rd_rst_busy()  // output wire rd_rst_busy
);
    
endmodule

`default_nettype wire

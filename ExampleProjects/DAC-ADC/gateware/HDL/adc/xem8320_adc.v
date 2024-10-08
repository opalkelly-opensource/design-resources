`timescale 1ns / 1ps
//------------------------------------------------------------------------
// xem8320_adc.v
//
// This is the top level module that instantiates the top level ADC file and 
// handles reset procedures. This module receives the data from the adc and 
// places it into a FIFO, where it can be read out through a pipe at endpoint 0xA0. 
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


module xem8320_adc(

    // ADC Pins
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin42_ctrl EP_TRIGGER" *)
    input  wire [31:0]         ti42_ep_trigger,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:triggerin:1.0 triggerin42_ctrl EP_CLK" *)
    output wire                ti42_ep_clk,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:wirein:1.0 wirein01 EP_DATAOUT" *)
    input  wire [31:0]         wi01_ep_reset,
    
    (* X_INTERFACE_INFO = "opalkelly.com:interface:pipeout:1.0 pipeouta0 EP_DATAIN" *)
    output wire [31:0]         poa0_data_out,
    (* X_INTERFACE_INFO = "opalkelly.com:interface:pipeout:1.0 pipeouta0 EP_READ" *)
    input  wire                poa0_ep_read,  
    
    input  wire                dac_clk,
    input  wire                okClk,
    output wire                adc_fifo_prog_full,
    output wire [4:0]          led,
    
    input  wire [1:0]          adc_out_1p, // Channel 1 data
    input  wire [1:0]          adc_out_1n,
    input  wire [1:0]          adc_out_2p, // Channel 2 data
    input  wire [1:0]          adc_out_2n,
    input  wire                adc_dco_p,      // ADC Data clock
    input  wire                adc_dco_n,
    input  wire                adc_fr_p,       // Frame input
    input  wire                adc_fr_n,
    output wire                adc_encode_p,   // ADC Encode Clock
    output wire                adc_encode_n,
    input  wire                adc_sdo,
    output wire                adc_sdi,
    output wire                adc_cs_n,
    output wire                adc_sck
    );

wire [31:0]  pipea0_data;

wire         adc_rdy;
wire         idelay_ref; 
wire         sys_clk_ibuf;
wire         sys_clk_bufg;
wire         rd_rst_busy;
wire         wr_rst_busy;
wire [15:0]  adc_data_out1, adc_data_out2;
wire         fifo_full;
reg          wr_en = 1'b0;
reg          fifo_reset;
reg          fifo_busy;

assign reset = wi01_ep_reset[0];
assign poa0_data_out = pipea0_data;
assign ti42_ep_clk = adc_data_clk;
assign fill_fifo = ti42_ep_trigger[0];
assign led = {2'd0, fifo_busy, adc_rdy, prog_full};
assign adc_fifo_prog_full = prog_full;

always @ (posedge adc_data_clk) begin
    if (adc_rdy && !prog_full && adc_data_valid) begin 
        if (fill_fifo) begin                // fifo wr_en logic to ensure the fifo:                       
            wr_en <= 1'b1;                  // operates after all SERDES modules are ready,              
        end                                 // isn't full, the adc data is valid (bitslip), and     
    end                                     // isn't resetting. 
    else begin                                                                                          
        wr_en <= 1'b0;                      
    end
end

reg [7:0] delay_counter = 8'd0;
reg [1:0] state;
localparam idle = 0,
           wait_for_lock = 3,
           reset_state = 1,
           delay_wait = 2;

// Worst case is using ADC-12 project, in which
// okClk (100.8 MHz) is 2.52x faster than adc_clk (40 MHz)
// first wait for MMCM to lock, then the
// reset should be asserted for 21 cycles,
// and then should wait for 152 cycles, for a
// total of 173 cycles the FIFO is resetting.
// See PG057 Figure 3-29 for more information.
always @ (posedge okClk) begin
    case (state)
        idle: begin
            if (reset) begin
                fifo_reset <= 1'b1;
                state <= wait_for_lock;
                fifo_busy <= 1'b1;
            end
            else begin
                fifo_busy <= 1'b0;
                fifo_reset <= 1'b0;
            end
        end
        
        wait_for_lock: begin // wait for MMCM to lock
            if (adc_rdy) begin
                delay_counter <= 8'd21;
                state <= reset_state;
            end
        end
        
        reset_state: begin // assert reset for 21 cycles after MMCM is locked
            delay_counter <= delay_counter - 1'b1;
            if (delay_counter == 8'd0) begin
                fifo_reset <= 1'b0;
                delay_counter <= 8'd152;
                state <= delay_wait;
            end 
        end
        
        delay_wait: begin // deassert fifo_busy after 152 cycles
            delay_counter <= delay_counter - 1'b1;
            if (delay_counter == 8'd0) begin
                fifo_busy <= 1'b0;
                state <= idle;
            end
        end
    endcase
end

syzygy_adc_top adc_impl(
    .clk           (dac_clk),
    .reset_async   (reset),
    .adc_out_1p    (adc_out_1p),
    .adc_out_1n    (adc_out_1n),
    .adc_out_2p    (adc_out_2p),
    .adc_out_2n    (adc_out_2n),
    .adc_dco_p     (adc_dco_p),
    .adc_dco_n     (adc_dco_n),
    .adc_fr_p      (adc_fr_p),
    .adc_fr_n      (adc_fr_n),
    .adc_encode_p  (adc_encode_p),
    .adc_encode_n  (adc_encode_n),
    .adc_sdo       (adc_sdo),
    .adc_sdi       (adc_sdi),
    .adc_cs_n      (adc_cs_n),
    .adc_sck       (adc_sck),
    .adc_data_clk  (adc_data_clk),
    .adc_data_1    (adc_data_out1),
    .adc_data_2    (adc_data_out2),
    .data_valid    (adc_data_valid),
    .rdy           (adc_rdy)
);

 fifo_generator_0 fifo(
    .wr_clk         (adc_data_clk),
    .rd_clk         (okClk),
    .rst            (fifo_reset),
    .din            ({adc_data_out1,adc_data_out2}),
    .wr_en          ({wr_en & ~fifo_busy}),
    .rd_en          ({poa0_ep_read & ~fifo_busy}),
    .dout           ({pipea0_data[7:0], pipea0_data[15:8], pipea0_data[23:16], pipea0_data[31:24]}), 
    .full           (fifo_full),
    .wr_rst_busy    (wr_rst_busy),
    .rd_rst_busy    (rd_rst_busy),
    .empty          (),
    .prog_full      (prog_full)
);  
endmodule

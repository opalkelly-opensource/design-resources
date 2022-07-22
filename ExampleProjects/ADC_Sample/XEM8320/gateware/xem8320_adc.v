`timescale 1ns / 1ps
//------------------------------------------------------------------------
// xem8320_adc.v
//
// This is the top level module that generates the clocks (IDELAY_REF and 
// the adc's encode clock) for use by the adc interfacing modules. This 
// module will received the data from the adc and place it into a FIFO, 
// where it can be read out through a pipe at endpoint 0xA0. 
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


module xem8320_adc(
    input  wire [4:0]          okUH,
    output wire [2:0]          okHU,
    inout  wire [31:0]         okUHU,
    inout  wire                okAA,

    // ADC Pins
    input  wire                sys_clkp,
    input  wire                sys_clkn,
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
    output wire [5:0]          led,
    output wire                adc_sck
    );


// Target interface bus:
wire         okClk;
wire [112:0] okHE;
wire [64:0]  okEH;

wire [31:0]  ep40trig;
wire [31:0]  ep00data;
wire [31:0]  pipea0_data;

wire         locked;
wire         idelay_ref; 
wire         sys_clk_ibuf;
wire         sys_clk_bufg;
wire         rd_rst_busy;
wire         wr_rst_busy;
wire [15:0]  adc_data_out1, adc_data_out2;
reg          wr_en = 1'b0;
reg          fifo_reset;

assign reset = ep00data[0];
assign fill_fifo = ep40trig[0];
assign led = {3'd0, fifo_busy, idelay_rdy, prog_full};

always @ (posedge adc_data_clk) begin
    if (locked && idelay_rdy && !prog_full && adc_data_valid) begin 
        if (fill_fifo) begin                // fifo wr_en logic to ensure the fifo:                       
            wr_en <= 1'b1;                  // operates after all SERDES modules are ready,              
        end                                 // isn't full, the adc data is valid (bitslip), and     
    end                                     // isn't resetting. 
    else begin                                                                                          
        wr_en <= 1'b0;                      
    end
end

reg [15:0] delay_counter = 16'd0;
reg [1:0] state;
reg fifo_busy;
localparam idle = 0,
           wait_for_lock = 1,
           reset_state = 2,
           delay_wait = 3;
 
always @ (posedge okClk) begin
    case (state)
        idle: begin
            delay_counter = 16'd400;
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
        wait_for_lock: begin
            if (locked) begin
                state <= reset_state;
            end
        end
        reset_state: begin
            delay_counter <= delay_counter - 1'b1;
            if (delay_counter < 16'd380) begin
                fifo_reset <= 1'b0;
                fifo_busy <= 1'b0;
                state <= delay_wait;
            end 
        end
        delay_wait: begin
            delay_counter <= delay_counter - 1'b1;
            if (delay_counter == 16'd0) begin
                state <= idle;
            end
        end
    endcase
end

syzygy_adc_top adc_impl(
    .clk           (adc_clk),
    .idelay_ref    (idelay_ref),
    .reset_async   (reset),
    .mmcm_locked   (locked),
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
    .rdy           (idelay_rdy)
);
IBUFDS sysclk_ibufds_inst (
    .O  (sys_clk_ibuf),     // 1-bit output: Buffer diff_p output
    // 1-bit output: Buffer diff_n output
    .I  (sys_clkp),         // 1-bit input: Diff_p buffer input (connect directly to top-level port)
    .IB (sys_clkn)          // 1-bit input: Diff_n buffer input (connect directly to top-level port)
   );
   
BUFG sys_clk_bufg_inst (
    .O(sys_clk_bufg), // 1-bit output: Clock output.
    .I(sys_clk_ibuf)  // 1-bit input: Clock input.
);
clk_wiz_0 idelay_adc_enc_clk(
    // Clock out ports  
    .clk_out1     (idelay_ref), // 300 MHz
    .clk_out2     (adc_clk),    // 40 MHz (default, SZG-ADC-12) or 125 MHz (SZG-ADC-14)
    .locked       (locked),
    // Clock in ports
    .reset        (reset),
    .clk_in1      (sys_clk_bufg)
);

 fifo_generator_0 fifo(
    .wr_clk         (adc_data_clk),
    .rd_clk         (okClk),
    .rst            (fifo_reset),
    .din            ({adc_data_out1,adc_data_out2}),
    .wr_en          ({wr_en & ~fifo_busy}),
    .rd_en          ({ep_read & ~fifo_busy}),
    .dout           ({pipea0_data[7:0], pipea0_data[15:8], pipea0_data[23:16], pipea0_data[31:24]}), 
    .full           (),
    .wr_rst_busy    (wr_rst_busy),
    .rd_rst_busy    (rd_rst_busy),
    .empty          (),
    .prog_full      (prog_full)
);
    

// Instantiate the okHost and connect endpoints.
wire [65*1-1:0]  okEHx;
okHost okHI(
    .okUH(okUH),
    .okHU(okHU),
    .okUHU(okUHU),
    .okAA(okAA),
    .okClk(okClk),
    .okHE(okHE), 
    .okEH(okEH)
);

okWireOR # (.N(1)) wireOR (okEH, okEHx);

okTriggerIn trigIn53    (.okHE(okHE), .ep_addr(8'h40), .ep_clk(adc_data_clk), .ep_trigger(ep40trig));
okWireIn wire00         (.okHE(okHE), .ep_addr(8'h00), .ep_dataout(ep00data));
okPipeOut pipeOuta0     (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'ha0), .ep_read(ep_read), .ep_datain(pipea0_data));   
endmodule

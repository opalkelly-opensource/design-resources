//------------------------------------------------------------------------
// syzygy-brain-adc.v
//
// This sample desmonstrates usage of the POD-ADC-LTC226x SYZYGY module
// from Opal Kelly. This sample is setup to interface with an ADC Pod
// connected on PORT D.
//
// Communication with the ADC itself is handled by the syzygy-adc-top
// module which returns parallel data from each of the ADC channels. This
// data is then fed into a FIFO and DMA through to the Zynq DRAM as part
// of the block design 'design_1'.
// 
//------------------------------------------------------------------------
// Copyright (c) 2018 Opal Kelly Incorporated
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

module xem7320_adc(
    input  wire [4:0]          okUH,
    output wire [3:0]          okHU,
	input  wire [3:0]          okRSVD,
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
    output wire [7:0]          led,
    output wire                adc_sck
    );


// Target interface bus:
wire         okClk;
wire [112:0] okHE;
wire [64:0]  okEH;

wire [31:0]  ep40trig;
wire [31:0]  ep00data;
wire [31:0]  pipea0_data;

wire         reset;
wire         idelay_rdy;
wire         ep_read;
wire         adc_data_clk;
wire         adc_clk;
wire         adc_data_valid;
wire         prog_full;
wire         fill_fifo;
wire [7:0]   status_signals;
wire         enc_clk_locked;
wire         locked;
wire         sys_clk_ibuf;
wire         sys_clk_bufg;
wire         rd_rst_busy;
wire         wr_rst_busy;
wire [15:0]  adc_data_out1, adc_data_out2;
reg          wr_en = 1'b0;
reg          fifo_reset;
reg          fifo_busy;

assign locked = idelay_rdy & enc_clk_locked;
assign reset = ep00data[0];
assign fill_fifo = ep40trig[0];
assign status_signals = {2'd0, enc_clk_locked, idelay_rdy, adc_data_valid, fifo_busy, locked, prog_full};
function [7:0] xem7320_led;
input [7:0] a;
integer i;
begin
	for(i=0; i<8; i=i+1) begin: u
		xem7320_led[i] = (a[i]==1'b1) ? (1'b0) : (1'bz);
	end
end
endfunction

assign led = xem7320_led(status_signals);

always @ (posedge adc_data_clk) begin
    if (locked && !prog_full && adc_data_valid) begin 
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
            if (locked) begin
                delay_counter = 8'd21;
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

wire idelay_ref;
enc_clk enc_clk_inst
   (
    // Clock out ports
    .clk_out1(adc_clk),     // output clk_out1
    .clk_out2(idelay_ref),
    // Status and control signals
    .reset(reset), // input reset
    .locked(enc_clk_locked),       // output locked
   // Clock in ports
    .clk_in1_p(sys_clkp),      // input clk_in1
    .clk_in1_n(sys_clkn)      // input clk_in1
);

syzygy_adc_top adc_impl(
	.clk          (adc_clk),
	.idelay_ref   (idelay_ref),
	.reset_async  (reset),
	
	.adc_out_1p   (adc_out_1p),
	.adc_out_1n   (adc_out_1n),
	.adc_out_2p   (adc_out_2p),
	.adc_out_2n   (adc_out_2n),
	.adc_dco_p    (adc_dco_p),
	.adc_dco_n    (adc_dco_n),
	.adc_fr_p     (adc_fr_p),
	.adc_fr_n     (adc_fr_n),
	.adc_encode_p (adc_encode_p),
	.adc_encode_n (adc_encode_n),
	.adc_sdo      (adc_sdo),
	.adc_sdi      (adc_sdi),
	.adc_cs_n     (adc_cs_n),
	.adc_sck      (adc_sck),
	
	.adc_data_clk (adc_data_clk),
	.adc_data_1   (adc_data_out1),
	.adc_data_2   (adc_data_out2),
	.data_valid   (adc_data_valid),
	.idelay_rdy   (idelay_rdy)
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
	.okRSVD(okRSVD),
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
`default_nettype wire

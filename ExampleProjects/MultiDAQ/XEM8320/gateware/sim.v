//------------------------------------------------------------------------
// A simple test bench template for simulating a top level user design
// utilizing FrontPanel. This file is "Read-only" and cannot be modified
// by the user. Follow these instructions to get started:
// 1. Create a top level test bench file within the "Simulation" file group
// 2. Copy and paste the contents of this template file into the newly
//    created file
// 3. Substitute "USER_TOP_LEVEL_MODULE" with the instantiation of the top
//    level module you wish to simulate
// 4. Add in the desired FrontPanel API simulation function calls listed
//    at the bottom of this template
//
//------------------------------------------------------------------------
// Copyright (c) 2022 Opal Kelly Incorporated
//------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none

module sim;

wire  [4:0]   okUH;
wire  [2:0]   okHU;
wire  [31:0]  okUHU;
wire          okAA;
reg          sys_clkp;
reg          sys_clkn;
reg dbg_rst;
reg clk_rst;
wire ADC_SDI_C;
wire ADC_SDO_C;
wire ADC_SCLK_C;
wire ADC_RST;
wire ADC_CS_N_C;
wire DAC_SDI_C;
wire DAC_SDO_C;
wire DAC_SCLK_C;
wire DAC_CS_N_C;
wire [7:0] led;
reg [15:0] ctr = 16'd0;
wire data;
reg [15:0] dummy_data = 16'hFF00;
assign data = dummy_data[15];
// Clock Generation
parameter tsys_clk = 5; // Half of the sys clk period
always begin
    #tsys_clk sys_clkp <= ~sys_clkp;
    sys_clkn <= ~sys_clkn;
end

always @(posedge ADC_SCLK_C) begin
    dummy_data[15:1] <= dummy_data[14:0];
    dummy_data[0] <= dummy_data[15];
end

// Change to your top level module
multidaq dut (
    .okUH(okUH),
    .okHU(okHU),
    .okUHU(okUHU),
    .okAA(okAA),
    // Add in the top level ports for your design below:
    .sys_clkp(sys_clkp),
    .sys_clkn(sys_clkn),
    .ADC_SDI_C(ADC_SDI_C),
    .ADC_SDO_C(data),
    .ADC_SCLK_C(ADC_SCLK_C),
    .ADC_RST(ADC_RST),
    .ADC_CS_N_C(ADC_CS_N_C),
	.DAC_SDI_C(DAC_SDI_C),
	.DAC_SDO_C(DAC_SDO_C),
	.DAC_SCLK_C(DAC_SCLK_C),
	.DAC_CS_N_C(DAC_CS_N_C)
);

//------------------------------------------------------------------------
// Begin okHostInterface simulation user configurable global data
//------------------------------------------------------------------------
parameter BlockDelayStates = 5;   // REQUIRED: # of clocks between blocks of pipe data
parameter ReadyCheckDelay = 5;    // REQUIRED: # of clocks before block transfer before
                                  //  host interface checks for ready (0-255)
parameter PostReadyDelay = 5;     // REQUIRED: # of clocks after ready is asserted and
                                  //  check that the block transfer begins (0-255)
parameter pipeInSize = 128;       // REQUIRED: byte (must be even) length of default
                                  //  PipeIn; Integer 0-2^32
parameter pipeOutSize = 128;      // REQUIRED: byte (must be even) length of default
                                  // PipeOut; Integer 0-2^32
parameter registerSetSize = 32;   // Size of array for register set commands.

parameter Tsys_clk = 5;           // 100Mhz
//-------------------------------------------------------------------------

// Pipes
integer k;
reg  [7:0]  pipeIn [0:(pipeInSize-1)];
initial for (k=0; k<pipeInSize; k=k+1) pipeIn[k] = 8'h00;

reg  [7:0]  pipeOut [0:(pipeOutSize-1)];
initial for (k=0; k<pipeOutSize; k=k+1) pipeOut[k] = 8'h00;

// Registers
reg [31:0] u32Address  [0:(registerSetSize-1)];
reg [31:0] u32Data     [0:(registerSetSize-1)];
reg [31:0] u32Count = 32'd0;


//------------------------------------------------------------------------
//  Available User Task and Function Calls:
//    FrontPanelReset;                 // Always start routine with FrontPanelReset;
//    SetWireInValue(ep, val, mask);
//    UpdateWireIns;
//    UpdateWireOuts;
//    GetWireOutValue(ep);
//    ActivateTriggerIn(ep, bit);      // bit is an integer 0-31
//    UpdateTriggerOuts;
//    IsTriggered(ep, mask);           // Returns a 1 or 0
//    WriteToPipeIn(ep, length);       // passes pipeIn array data
//    ReadFromPipeOut(ep, length);     // passes data to pipeOut array
//    WriteToBlockPipeIn(ep, blockSize, length);   // pass pipeIn array data; blockSize and length are integers
//    ReadFromBlockPipeOut(ep, blockSize, length); // pass data to pipeOut array; blockSize and length are integers
//    WriteRegister(address, data);
//    ReadRegister(address, data);
//    WriteRegisterSet;                // writes all values in u32Data to the addresses in u32Address
//    ReadRegisterSet;                 // reads all values in the addresses in u32Address to the array u32Data
//
//    *Pipes operate by passing arrays of data back and forth to the user's
//    design.  If you need multiple arrays, you can create a new procedure
//    above and connect it to a differnet array.  More information is
//    available in Opal Kelly documentation and online support tutorial.
// WireIn    0x00      0 - clock reset
//           0x00      1 - adc hw reset
//           0x00      2 - Start ADC
//           0x00      3 - Unused
//           0x00   7: 4 - ADC channel count (0-7)
//           0x00  15: 8 - DAC channel count (One hot for each individual channel)
//           0x01  31: 0 - DAC Ch1 frequency
//           ....  31: 0 - DAC Chx frequency
//           0x08  31: 0 - DAC Ch8 frequency
//
// WireOut   0x28      0 - Send FIFO Prog full signal
// PipeOut   0xA0  31:16 - ADC channel number
//                 15: 0 - ADC Channel Data
//------------------------------------------------------------------------

wire [31:0] NO_MASK = 32'hffff_ffff;
integer i;

initial begin
    sys_clkp <= 1'b0;
    sys_clkn <= 1'b1;
    FrontPanelReset;
    #2000;
    // auto reset
    SetWireInValue(8'h00, 32'h00000004, NO_MASK);
    SetWireInValue(8'h01, 32'h000FFFFF, NO_MASK);
    UpdateWireIns;
    #1000;
    SetWireInValue(8'h00, 32'h00000110, NO_MASK);
    UpdateWireIns;
    #400000;
    $finish;
    
end

`include "./okHostCalls.vh"   // Do not remove!  The tasks, functions, and data stored
                             // in okHostCalls.vh must be included here.
endmodule

`default_nettype wire

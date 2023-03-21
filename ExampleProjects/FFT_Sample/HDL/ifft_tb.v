//------------------------------------------------------------------------
// A simple test bench for simulating the FFT Signal Generator sample.
//
//------------------------------------------------------------------------
// Copyright (c) 2023 Opal Kelly Incorporated
//------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none

module ifft_tb;

wire  [4:0]   okUH;
wire  [2:0]   okHU;
wire  [31:0]  okUHU;
wire          okAA;
wire          dac_cs_n_0;
wire          dac_reset_pinmd_0;
wire          dac_clk_0;
wire          dac_sdio_0;
wire          dac_sclk_0;
wire  [11:0]  dac_data_o_0;
// Change to your top level module
ifft_wrapper wrapper
   (
    .dac_clk_0(dac_clk_0),
    .dac_cs_n_0(dac_cs_n_0),
    .dac_data_o_0(dac_data_o_0),
    .dac_reset_pinmd_0(dac_reset_pinmd_0),
    .dac_sclk_0(dac_sclk_0),
    .dac_sdio_0(dac_sdio_0),
    .host_interface_okaa(okAA),
    .host_interface_okhu(okHU),
    .host_interface_okuh(okUH),
    .host_interface_okuhu(okUHU)
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
reg [31:0] u32Count;


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
//------------------------------------------------------------------------

wire [31:0] NO_MASK = 32'hffff_ffff;
integer count = 0;
reg [31:0] bram_data;
initial begin
    FrontPanelReset;
    #60
    UpdateWireOuts;
    while(!(GetWireOutValue(8'h20) & 32'h0000_0001)) begin // Wait for clocks to lock
        #10
        UpdateWireOuts;
    end
    SetWireInValue(8'h00, 32'h0000_0002, 32'hFFFF_FFFF); // Logic reset
    UpdateWireIns;
    #60
    SetWireInValue(8'h00, 32'h0000_0000, 32'hFFFF_FFFF);
    UpdateWireIns;
    
    // Initialize BRAM to all 0
    repeat (512) begin
        WriteRegister(count, 32'h0000_0000);
        count = count + 1;
    end
    #60
    WriteRegister(9'd0, 32'h0000_0000); // dc component
    WriteRegister(9'd1, 32'h0000_0000); // dc component
    
    WriteRegister(9'd2, 32'h0003_FFFF); // bin 1 real component
    WriteRegister(9'd12, 32'h0003_FFFF); // bin 6 real component
    #200 
    ActivateTriggerIn(8'h40, 1); // send new bin data to IFFT core and DAC
    #40000
    $finish;
end

`include "./okHostCalls.vh"   // Do not remove!  The tasks, functions, and data stored
                             // in okHostCalls.vh must be included here.
endmodule

`default_nettype wire

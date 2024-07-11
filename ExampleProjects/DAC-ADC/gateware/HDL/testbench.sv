//------------------------------------------------------------------------
// A simple test bench for simulating the FFT Signal Generator sample.
//
//------------------------------------------------------------------------
// Copyright (c) 2024 Opal Kelly Incorporated
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
wire          dac_clk_o_0;
wire          dac_sdio_0;
wire          dac_sclk_0;
wire  [11:0]  dac_data_o_0;
// Change to your top level module
adc_dac_tester wrapper
   (
    .adc_cs_n_0(),
    .adc_dco_n_0(),
    .adc_dco_p_0(),
    .adc_encode_n_0(),
    .adc_encode_p_0(),
    .adc_fr_n_0(),
    .adc_fr_p_0(),
    .adc_out_1n_0(),
    .adc_out_1p_0(),
    .adc_out_2n_0(),
    .adc_out_2p_0(),
    .adc_sck_0(),
    .adc_sdi_0(),
    .adc_sdo_0(),
    .board_leds_led_out(),
    .dac_clk_o_0(dac_clk_o_0),
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
parameter pipeInSize = 2048;       // REQUIRED: byte (must be even) length of default
                                  //  PipeIn; Integer 0-2^32
parameter pipeOutSize = 4096;      // REQUIRED: byte (must be even) length of default
                                  // PipeOut; Integer 0-2^32
parameter registerSetSize = 32;   // Size of array for register set commands.

parameter Tsys_clk = 5;           // 100Mhz
//-------------------------------------------------------------------------

// Pipes
integer k;
integer i;
integer temp;
// Sample ADC data
reg  [15:0]  pipeInT [0:(1023)]= '{-57, -47, -36, -20, -6, 8, 19, 32, 44, 52, 59, 62, 63, 62, 60, 50, 42, 31, 19, 2, -7, -24, -34, -48, -59, -67, -74, -79, -76, -76, -74, -64, -57, -43, -30, -18, -4, 6, 23, 35, 44, 54, 59, 62, 63, 58, 55, 50, 41, 27, 14, 1, -10, -26, -39, -51, -62, -69, -76, -76, -75, -73, -70, -61, -51, -39, -25, -12, 1, 11, 26, 39, 49, 56, 59, 62, 64, 60, 53, 46, 36, 24, 10, -4, -19, -31, -45, -58, -67, -71, -77, -79, -76, -74, -69, -59, -48, -37, -23, -9, 4, 17, 32, 39, 50, 58, 62, 65, 61, 59, 52, 45, 35, 19, 5, -7, -22, -32, -45, -56, -66, -76, -79, -80, -77, -75, -70, -56, -46, -37, -20, -6, 5, 20, 32, 43, 52, 57, 64, 64, 64, 59, 50, 43, 31, 20, 6, -8, -22, -37, -46, -60, -69, -77, -78, -77, -76, -73, -66, -56, -45, -31, -17, -4, 11, 23, 34, 44, 54, 60, 65, 63, 62, 56, 48, 37, 27, 14, 1, -14, -26, -41, -54, -61, -72, -77, -78, -78, -75, -72, -63, -54, -43, -29, -13, 2, 15, 28, 39, 48, 57, 63, 64, 61, 61, 55, 46, 36, 19, 9, -6, -18, -34, -45, -55, -66, -73, -79, -80, -79, -77, -71, -62, -49, -39, -23, -9, 1, 20, 32, 40, 52, 60, 62, 63, 62, 57, 54, 45, 34, 19, 9, -7, -22, -35, -44, -57, -67, -74, -79, -79, -79, -76, -66, -59, -47, -34, -20, -7, 5, 20, 31, 43, 52, 59, 63, 64, 60, 59, 50, 43, 31, 19, 4, -10, -23, -35, -50, -58, -69, -74, -76, -78, -76, -74, -65, -56, -44, -32, -17, -3, 9, 24, 37, 47, 55, 61, 62, 64, 59, 57, 49, 39, 26, 10, 2, -14, -27, -39, -53, -63, -70, -77, -80, -77, -77, -69, -62, -53, -38, -27, -11, 3, 12, 28, 40, 48, 56, 61, 65, 62, 60, 55, 48, 35, 23, 10, -4, -17, -31, -45, -56, -66, -75, -77, -77, -78, -74, -69, -59, -48, -34, -24, -7, 5, 18, 33, 44, 52, 59, 65, 63, 63, 60, 53, 44, 35, 20, 7, -6, -21, -35, -44, -58, -66, -73, -76, -76, -77, -71, -65, -56, -47, -32, -20, -4, 7, 20, 35, 46, 54, 60, 67, 67, 62, 60, 52, 42, 34, 18, 6, -8, -24, -33, -46, -56, -67, -73, -78, -74, -75, -72, -63, -57, -41, -28, -16, -2, 13, 23, 35, 47, 54, 61, 61, 61, 60, 57, 49, 37, 27, 16, 1, -13, -28, -40, -53, -61, -72, -77, -78, -76, -74, -70, -62, -52, -38, -26, -12, 0, 15, 26, 39, 48, 58, 61, 65, 63, 60, 53, 47, 39, 22, 8, -6, -19, -30, -47, -57, -66, -72, -79, -80, -78, -76, -67, -62, -49, -37, -23, -9, 2, 15, 29, 41, 49, 58, 63, 63, 63, 58, 50, 44, 31, 20, 5, -8, -21, -34, -47, -58, -69, -73, -78, -78, -78, -75, -67, -60, -47, -35, -22, -6, 5, 18, 33, 42, 53, 58, 61, 62, 61, 56, 52, 41, 29, 18, 3, -12, -24, -36, -50, -59, -69, -76, -78, -78, -74, -73, -66, -55, -45, -31, -18, -2, 9, 23, 36, 44, 54, 61, 61, 61, 60, 55, 49, 34, 26, 15, 1, -12, -30, -43, -54, -65, -72, -74, -78, -77, -74, -71, -62, -49, -41, -24, -13, 1, 15, 28, 38, 50, 56, 64, 62, 62, 59, 51, 44, 34, 23, 11, -6, -20, -31, -45, -59, -66, -72, -77, -79, -76, -72, -69, -59, -49, -36, -22, -9, 6, 20, 31, 43, 51, 60, 61, 63, 61, 59, 50, 44, 34, 20, 5, -8, -22, -34, -44, -59, -68, -76, -78, -79, -77, -73, -67, -58, -46, -35, -20, -4, 8, 21, 33, 45, 53, 60, 62, 64, 61, 56, 50, 40, 29, 18, 2, -10, -26, -38, -50, -60, -69, -76, -76, -76, -75, -71, -64, -56, -41, -27, -17, -3, 9, 25, 36, 45, 53, 63, 63, 64, 62, 58, 49, 35, 25, 11, -2, -13, -30, -42, -53, -64, -73, -78, -79, -76, -75, -70, -62, -51, -37, -25, -8, 0, 15, 26, 42, 51, 57, 60, 62, 62, 60, 54, 45, 34, 21, 11, -5, -19, -31, -46, -58, -64, -75, -77, -80, -79, -74, -70, -60, -48, -35, -23, -11, 4, 18, 29, 42, 51, 58, 63, 64, 62, 59, 53, 42, 31, 19, 6, -9, -21, -34, -46, -59, -68, -76, -78, -76, -77, -73, -69, -57, -47, -32, -19, -3, 8, 20, 34, 44, 52, 60, 62, 61, 61, 58, 51, 41, 29, 18, 2, -8, -24, -40, -49, -57, -69, -75, -78, -77, -76, -72, -65, -55, -42, -31, -14, -1, 10, 23, 35, 45, 55, 60, 63, 63, 60, 57, 45, 37, 25, 12, -1, -16, -28, -43, -53, -65, -72, -76, -78, -78, -76, -70, -61, -52, -38, -26, -12, 3, 15, 27, 41, 49, 56, 62, 65, 60, 60, 54, 45, 35, 21, 8, -7, -17, -31, -46, -57, -65, -74, -79, -79, -78, -75, -69, -61, -47, -33, -23, -9, 5, 20, 30, 45, 51, 58, 62, 63, 63, 58, 54, 43, 30, 20, 5, -8, -20, -35, -48, -55, -68, -74, -77, -80, -77, -73, -67, -58, -45, -32, -20, -3, 8, 21, 34, 45, 55, 58, 62, 64, 60, 58, 51, 41, 29, 18, 2, -10, -24, -36, -48, -60, -68, -74, -78, -78, -75, -71, -62, -56, -44, -29, -15, -3, 11, 24, 36, 46, 54, 60, 62, 62, 59, 56, 48, 36, 26, 10, -5, -15, -28, -40, -52, -64, -71, -78, -80, -79, -73, -71, -62, -49, -37, -24, -9, 4, 18, 29, 41, 50, 56, 63, 63, 61, 62, 55, 45, 34, 22, 8, -9, -17, -32, -44, -58, -64, -73, -77, -79, -78, -74, -66, -56, -46, -37, -21, -8, 3, 19, 30, 42, 53, 58, 65, 63, 61, 61, 53, 43, 32, 17, 5, -6, -21, -36, -49, -58, -69, -74, -77, -79, -78, -73, -66, -57, -46, -34, -21, -5, 6, 22, 33};

reg  [7:0]  pipeIn [0:(2047)];
initial for (k=0,i=0; k<2048; k=k+2,i=i+1) begin
    temp = pipeInT[i];
    pipeIn[k] = temp[7:0];
    pipeIn[k+1] = temp[15:8];
    end

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
    
   SetWireInValue(8'h01, 32'h0000_0001, 32'hFFFF_FFFF); // Logic reset
    UpdateWireIns;
    #60
    SetWireInValue(8'h01, 32'h0000_0000, 32'hFFFF_FFFF);
    UpdateWireIns;
    
    // Initialize BRAM to all 0
    repeat (2048) begin
        WriteRegister(count, 32'h0000_0000);
        count = count + 1;
    end
    #60
    WriteRegister(10'd0, 32'h0000_0000); // dc component
    WriteRegister(10'd1, 32'h0000_0000); // dc component

    WriteRegister(10'd488, 32'h0003_FFFF); // bin 488 real component

    #200 
    ActivateTriggerIn(8'h40, 1); // send new bin data to IFFT core and DAC
    #40000
    
    WriteToPipeIn(8'h80, pipeInSize); // write adc data to FFT TX Fifo
    
    while(!(GetWireOutValue(8'h20) & 32'h0000_0010)) begin // Wait for FFT TX FIFO to fill (uses prog empty)
        #10
        UpdateWireOuts;
    end
    
    ActivateTriggerIn(8'h40, 2); //start fft calculation
    #200000
    
    while(GetWireOutValue(8'h20) & 32'h0000_0008) begin // Wait for FFT RX FIFO to fill (uses prog full)
        #10
        UpdateWireOuts;
    end
    
    ReadFromPipeOut(8'hA1, pipeInSize); // read fft calculation data output

    $finish;
end

`include "./okHostCalls.vh"   // Do not remove!  The tasks, functions, and data stored
                             // in okHostCalls.vh must be included here.
endmodule

`default_nettype wire

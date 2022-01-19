`timescale 1ns / 1ps
//------------------------------------------------------------------------
// FrontPanelWrapper_TriMAC.v
// 
// This example design's overview, requirements, and instructions are located at:
// https://docs.opalkelly.com/xem8320/getting-started/ethernet-reference-design/
//
// This is a top level wrapper that instantiates the following:
// - Two heavily modified Xilinx Tri-Mode Ethernet Media Access Controller 
//   (TEMAC) IP example designs.
// - FrontPanel components.
// - EEPROM MAC address extractor module.
// - MMCM to generate clock inputs into the modified Xilinx example designs.
//
// A valid license for the Xilinx Tri-Mode Ethernet Media Access Controller 
// (TEMAC) IP if you wish to build the project. You can request a 120 day 
// evaluation license through the Xilinx website. The pre-built bitfile already 
// includes an entitled evaluation license.
//
// Copyright (c) 2005-2021  Opal Kelly Incorporated
//------------------------------------------------------------------------


module FrontPanelWrapper_TriMAC(
    input  wire [4:0]  okUH,
    output wire [2:0]  okHU,
    inout  wire [31:0] okUHU,
    inout  wire        okAA,
    
    input  wire        fabric_100Mhz_p,
    input  wire        fabric_100Mhz_n,
    
    // RGMII Interface 1
    output wire [3:0]  rgmii_txd_1,
    output wire        rgmii_tx_ctl_1,
    output wire        rgmii_txc_1,
    input  wire [3:0]  rgmii_rxd_1,
    input  wire        rgmii_rx_ctl_1,
    input  wire        rgmii_rxc_1,

      
    // MDIO Interface 1
    inout  wire        mdio_1,
    output wire        mdc_1,
      
    // RGMII Interface 2
    output wire [3:0]  rgmii_txd_2,
    output wire        rgmii_tx_ctl_2,
    output wire        rgmii_txc_2,
    input  wire [3:0]  rgmii_rxd_2,
    input  wire        rgmii_rx_ctl_2,
    input  wire        rgmii_rxc_2,

      
    // MDIO Interface 2
    inout  wire        mdio_2,
    output wire        mdc_2,
    
    // Resets
    output wire        phy_resetn_1,
    output wire        phy_resetn_2,
    
    output wire [5:0]  led,
    
    inout              sclk_portA,
    inout              sdata_portA,
    inout              sclk_portC,
    inout              sdata_portC
);

parameter  Default_MACDestinationAddress_1 = 48'hda0203040506;
parameter  Default_MACSourceAddress_1      = 48'h5a0203040506;
parameter  Default_MACDestinationAddress_2 = 48'hda0203040506;
parameter  Default_MACSourceAddress_2      = 48'h5a0203040506;

// Target interface bus:
wire         okClk;
wire [112:0] okHE;
wire [64:0]  okEH;  

// Clock nets
wire         clk_out_IBUFDS;
wire         clk_out_IBUFDS_BUFG;
wire         clk_out_200Mhz;
wire         clk_out_200Mhz_locked;
    
// Endpoint connections:
wire [31:0]  ep00wire;
wire [31:0]  ep01wire;
wire [31:0]  ep02wire;

wire [31:0]  ep03wire;
wire [31:0]  ep04wire;
wire [31:0]  ep05wire;
wire [31:0]  ep06wire;
wire [31:0]  ep07wire;
wire [31:0]  ep08wire;
wire [31:0]  ep09wire;
wire [31:0]  ep10wire;

wire [31:0]  ep20wire;
wire [31:0]  ep21wire;
wire [31:0]  numOfPacketsSent_1;
wire [31:0]  numOfFramesReceived_1;
wire [31:0]  numOfPacketsSent_2;
wire [31:0]  numOfFramesReceived_2;

// Example design 1 nets:
wire         glbl_rst_1;
wire [1:0]   mac_speed_1;
wire         update_speed_1;
wire         config_board_1;
wire         gen_tx_data_1;
wire         chk_tx_data_1;
wire         reset_error_1;
wire         phy_link_status_1;
wire [1:0]   phy_clock_speed_1;
wire         phy_duplex_status_1;

// Example design 2 nets:
wire         glbl_rst_2;
wire [1:0]   mac_speed_2;
wire         update_speed_2;
wire         config_board_2;
wire         gen_tx_data_2;
wire         chk_tx_data_2;
wire         reset_error_2;
wire         phy_link_status_2;
wire [1:0]   phy_clock_speed_2;
wire         phy_duplex_status_2;

// LED nets
wire frame_error_1;
wire frame_error_2;
wire activity_indicator_1;
wire activity_indicator_2;


reg  [47:0]  MACDestinationAddress_1 = Default_MACDestinationAddress_1;
reg  [47:0]  MACSourceAddress_1      = Default_MACSourceAddress_1;
reg  [47:0]  MACDestinationAddress_2 = Default_MACDestinationAddress_2;
reg  [47:0]  MACSourceAddress_2      = Default_MACSourceAddress_2;
wire [47:0]  ExtractedMACAddress_1;
wire [47:0]  ExtractedMACAddress_2;
reg  [1:0]   mac_speed_1_reg;
reg  [1:0]   mac_speed_2_reg;
wire         extractDone_1;
wire         extractDone_2;
wire         loadAddresses_1;
wire         loadAddresses_2;

assign glbl_rst_1              = ep00wire[0];
assign glbl_rst_2              = ep00wire[1];
assign resetPacketCount_1      = ep00wire[2];
assign resetPacketCount_2      = ep00wire[3];
assign setAddressesToEachOther = ep00wire[4];

assign mac_speed_1             = ep01wire[1:0];
assign update_speed_1          = ep01wire[2];
assign config_board_1          = ep01wire[3];
assign gen_tx_data_1           = ep01wire[4];
assign chk_tx_data_1           = ep01wire[5];
assign reset_error_1           = ep01wire[6];
assign loopbackEn_1            = ep01wire[7];
assign injectError_1           = ep01wire[8];
assign enable_address_swap_1   = ep01wire[9];
assign enable_phy_loopback_1   = ep01wire[10];
assign setAddressesPortA       = ep01wire[11];

assign ep20wire[0]             = phy_link_status_1;
assign ep20wire[2:1]           = phy_clock_speed_1;
assign ep20wire[3]             = phy_duplex_status_1;
assign ep20wire[4]             = frame_error_1;
assign ep20wire[5]             = activity_indicator_1;


assign mac_speed_2             = ep02wire[1:0];
assign update_speed_2          = ep02wire[2];
assign config_board_2          = ep02wire[3];
assign gen_tx_data_2           = ep02wire[4];
assign chk_tx_data_2           = ep02wire[5];
assign reset_error_2           = ep02wire[6];
assign loopbackEn_2            = ep02wire[7];
assign injectError_2           = ep02wire[8];
assign enable_address_swap_2   = ep02wire[9];
assign enable_phy_loopback_2   = ep02wire[10];
assign setAddressesPortC       = ep02wire[11];

assign ep21wire[0]             = phy_link_status_2;
assign ep21wire[2:1]           = phy_clock_speed_2;
assign ep21wire[3]             = phy_duplex_status_2;
assign ep21wire[4]             = frame_error_2;
assign ep21wire[5]             = activity_indicator_2;

assign loadAddresses_1         = setAddressesPortA || setAddressesToEachOther;
assign loadAddresses_2         = setAddressesPortC || setAddressesToEachOther;

assign led = {activity_indicator_2, frame_error_2, 2'b00, activity_indicator_1, frame_error_1};

always @(posedge okClk) begin
    if (glbl_rst_1) begin
        mac_speed_1_reg <= 2'b00;
    end else if (update_speed_1) begin 
        mac_speed_1_reg <= mac_speed_1;
    end
end
always @(posedge okClk) begin
    if (glbl_rst_2) begin
        mac_speed_2_reg <= 2'b00;
    end else if (update_speed_2) begin 
        mac_speed_2_reg <= mac_speed_2;
    end
end

always @(posedge okClk) begin
    if (setAddressesToEachOther && (extractDone_1 && extractDone_2)) begin
        MACDestinationAddress_1 <= ExtractedMACAddress_2;
        MACSourceAddress_1      <= ExtractedMACAddress_1;
        MACDestinationAddress_2 <= ExtractedMACAddress_1;
        MACSourceAddress_2      <= ExtractedMACAddress_2;
    end else if (setAddressesPortA) begin 
        MACDestinationAddress_1 <= {ep04wire[15:0], ep03wire};
        MACSourceAddress_1      <= {ep06wire[15:0], ep05wire};
    end else if (setAddressesPortC) begin
        MACDestinationAddress_2 <= {ep08wire[15:0], ep07wire};
        MACSourceAddress_2      <= {ep10wire[15:0], ep09wire};
    end

end

// Instantiate the okHost and connect endpoints.
wire [65*18-1:0]  okEHx;
okHost okHI(
    .okUH(okUH),
    .okHU(okHU),
    .okUHU(okUHU),
    .okAA(okAA),
    .okClk(okClk),
    .okHE(okHE), 
    .okEH(okEH)
);

okWireOR # (.N(18)) wireOR (okEH, okEHx);

okWireIn     ep00 (.okHE(okHE),                              .ep_addr(8'h00), .ep_dataout(ep00wire));

okWireIn     ep01 (.okHE(okHE),                              .ep_addr(8'h01), .ep_dataout(ep01wire));
okWireIn     ep02 (.okHE(okHE),                              .ep_addr(8'h02), .ep_dataout(ep02wire));

okWireIn     ep03 (.okHE(okHE),                              .ep_addr(8'h03), .ep_dataout(ep03wire));
okWireIn     ep04 (.okHE(okHE),                              .ep_addr(8'h04), .ep_dataout(ep04wire));
okWireIn     ep05 (.okHE(okHE),                              .ep_addr(8'h05), .ep_dataout(ep05wire));
okWireIn     ep06 (.okHE(okHE),                              .ep_addr(8'h06), .ep_dataout(ep06wire));
okWireIn     ep07 (.okHE(okHE),                              .ep_addr(8'h07), .ep_dataout(ep07wire));
okWireIn     ep08 (.okHE(okHE),                              .ep_addr(8'h08), .ep_dataout(ep08wire));
okWireIn     ep09 (.okHE(okHE),                              .ep_addr(8'h09), .ep_dataout(ep09wire));
okWireIn     ep10 (.okHE(okHE),                              .ep_addr(8'h10), .ep_dataout(ep10wire));



okWireOut    ep20 (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]),  .ep_addr(8'h20), .ep_datain(ep20wire));
okWireOut    ep21 (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]),  .ep_addr(8'h21), .ep_datain(ep21wire));
okWireOut    ep22 (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]),  .ep_addr(8'h22), .ep_datain(numOfPacketsSent_1));
okWireOut    ep23 (.okHE(okHE), .okEH(okEHx[ 3*65 +: 65 ]),  .ep_addr(8'h23), .ep_datain(numOfFramesReceived_1));
okWireOut    ep24 (.okHE(okHE), .okEH(okEHx[ 4*65 +: 65 ]),  .ep_addr(8'h24), .ep_datain(numOfPacketsSent_2));
okWireOut    ep25 (.okHE(okHE), .okEH(okEHx[ 5*65 +: 65 ]),  .ep_addr(8'h25), .ep_datain(numOfFramesReceived_2));


okWireOut    ep26 (.okHE(okHE), .okEH(okEHx[ 6*65 +: 65 ]),  .ep_addr(8'h26), .ep_datain(MACDestinationAddress_1[31:0]));
okWireOut    ep27 (.okHE(okHE), .okEH(okEHx[ 7*65 +: 65 ]),  .ep_addr(8'h27), .ep_datain(MACDestinationAddress_1[47:32]));
okWireOut    ep28 (.okHE(okHE), .okEH(okEHx[ 8*65 +: 65 ]),  .ep_addr(8'h28), .ep_datain(MACSourceAddress_1[31:0]));
okWireOut    ep29 (.okHE(okHE), .okEH(okEHx[ 9*65 +: 65 ]),  .ep_addr(8'h29), .ep_datain(MACSourceAddress_1[47:32]));
okWireOut    ep30 (.okHE(okHE), .okEH(okEHx[ 10*65 +: 65 ]), .ep_addr(8'h30), .ep_datain(MACDestinationAddress_2[31:0]));
okWireOut    ep31 (.okHE(okHE), .okEH(okEHx[ 11*65 +: 65 ]), .ep_addr(8'h31), .ep_datain(MACDestinationAddress_2[47:32]));
okWireOut    ep32 (.okHE(okHE), .okEH(okEHx[ 12*65 +: 65 ]), .ep_addr(8'h32), .ep_datain(MACSourceAddress_2[31:0]));
okWireOut    ep33 (.okHE(okHE), .okEH(okEHx[ 13*65 +: 65 ]), .ep_addr(8'h33), .ep_datain(MACSourceAddress_2[47:32]));

okWireOut    ep34 (.okHE(okHE), .okEH(okEHx[ 14*65 +: 65 ]), .ep_addr(8'h34), .ep_datain(ExtractedMACAddress_1[31:0]));
okWireOut    ep35 (.okHE(okHE), .okEH(okEHx[ 15*65 +: 65 ]), .ep_addr(8'h35), .ep_datain(ExtractedMACAddress_1[47:32]));
okWireOut    ep36 (.okHE(okHE), .okEH(okEHx[ 16*65 +: 65 ]), .ep_addr(8'h36), .ep_datain(ExtractedMACAddress_2[31:0]));
okWireOut    ep37 (.okHE(okHE), .okEH(okEHx[ 17*65 +: 65 ]), .ep_addr(8'h37), .ep_datain(ExtractedMACAddress_2[47:32]));

// ------------------------Clocking Architecture--------------------------
// The XEM8320 has a 100Mhz fixed clock oscillator onboard the PCB. 
// The Xilinx example design sources expected a 200Mhz clock input 
// to come from a fixed clock oscillator on their development board. 
// This input came in on a IBUFDS primitive which was then input into 
// an MMCM. This input must be at 200Mhz for the MMCM's series of clock 
// divisions and multiplications to achieve the desired clock outputs for 
// the example design.
//
// We have removed the IBUFDS within the example design sources and have instead 
// instantiated it here at the top level. We configure an MMCM from the clock 
// wizard to input the 100Mhz oscillator from the XEM8320 and output the 200Mhz 
// required by the two Xilinx example design instatiations.
// 
// The Opal Kelly okHost instantiation is using the MMCM within the same clock 
// region as the oscillator input pins. Because this clock input requires a 
// sub-optimal route to an MMCM within another region we use the BUFG and a 
// BACKBONE constraint on the MMCM clock input in the constraints file. A 
// similar BACKBONE constraint is required for the MMCM clock inputs of the 
// MMCMs within the Xilinx example design as these will be located far away 
// from the MMCM generating the clock input and will require a sub-optimal route. 
// The MMCMs are only used for frequency synthesis and the added delay is of no concern. 
IBUFDS clkin1_ibufds (   
    .O                    (clk_out_IBUFDS),           // output
    .I                    (fabric_100Mhz_p),          // input
    .IB                   (fabric_100Mhz_n)           // input
);
BUFG clkin1_bufg (   
    .O                    (clk_out_IBUFDS_BUFG),      // output
    .I                    (clk_out_IBUFDS)            // input
);
clk_wiz_100Mhz clk_wiz_100Mhz_i (
    .clk_out1             (clk_out_200Mhz),           // output
    .locked               (clk_out_200Mhz_locked),    // output
    .clk_in1              (clk_out_IBUFDS_BUFG)       // input
);  
   
ExtractMACAddress ExtractMACAddress_1_i (
    .okClk                (okClk),                    // input
    .rst                  (glbl_rst_1),               // input
    .sclk                 (sclk_portA),               // input
    .sdata                (sdata_portA),              // input
    
    .MACAddr              (ExtractedMACAddress_1),    // output  [47:0]
    .done                 (extractDone_1)             // output
);
  
ExtractMACAddress ExtractMACAddress_2_i (
    .okClk                (okClk),                    // input
    .rst                  (glbl_rst_2),               // input
    .sclk                 (sclk_portC),               // input
    .sdata                (sdata_portC),              // input
    
    .MACAddr              (ExtractedMACAddress_2),    // output  [47:0]
    .done                 (extractDone_2)             // output
); 

EthernetMac_1_example_design EthernetMac_1_example_design_i (
    // asynchronous reset
    .glbl_rst             (glbl_rst_1),               // input

    // Opal Kelly edit:
    // 200MHz clock input from MMCM
    .clk_in               (clk_out_200Mhz),           // input
    // 125 MHz clock from MMCM
    .gtx_clk_bufg_out     (),                         // output

    .phy_resetn           (phy_resetn_1),             // output


    // RGMII Interface
    .rgmii_txd            (rgmii_txd_1),              // output  [3:0]
    .rgmii_tx_ctl         (rgmii_tx_ctl_1),           // output
    .rgmii_txc            (rgmii_txc_1),              // output
    .rgmii_rxd            (rgmii_rxd_1),              // input   [3:0]
    .rgmii_rx_ctl         (rgmii_rx_ctl_1),           // input
    .rgmii_rxc            (rgmii_rxc_1),              // input


    // MDIO Interface
    .mdio                 (mdio_1),                   // inout
    .mdc                  (mdc_1),                    // output


    // Serialised statistics vectors
    .tx_statistics_s      (),                         // output
    .rx_statistics_s      (),                         // output

    // Serialised Pause interface controls
    .pause_req_s          (),                         // input

    // Main example design controls
    .mac_speed            (mac_speed_1_reg),          // input   [1:0]
    .update_speed         (update_speed_1),           // input
    .enable_address_swap  (enable_address_swap_1),    // input
    .enable_phy_loopback  (enable_phy_loopback_1),    // input
    .serial_response      (),                         // output
    .gen_tx_data          (gen_tx_data_1),            // input
    .chk_tx_data          (chk_tx_data_1),            // input
    .reset_error          (reset_error_1),            // input
    .frame_error          (led[0]),                   // output
    .frame_errorn         (),                         // output
    .activity_flash       (led[1]),                   // output
    .activity_flashn      (),                         // output


    .inband_link_status   (phy_link_status_1),        // output
    .inband_clock_speed   (phy_clock_speed_1),        // output  [1:0]
    .inband_duplex_status (phy_duplex_status_1),      // output
    .numOfPacketsSent     (numOfPacketsSent_1),       // output  [31:0]
    .numOfFramesReceived  (numOfFramesReceived_1),    // output  [31:0]
    .resetPacketCount     (resetPacketCount_1),       // input
    .loopbackEn           (loopbackEn_1),             // input
    .injectError          (injectError_1),            // input
    .loadAddresses        (loadAddresses_1),          // input
    .sourceAddress        (MACSourceAddress_1),       // input   [47:0]
    .destinationAddress   (MACDestinationAddress_1)   // input   [47:0]
);   
    
    
EthernetMac_1_example_design EthernetMac_2_example_design_i (
    // asynchronous reset
    .glbl_rst             (glbl_rst_2),               // input

    // Opal Kelly edit:
    // 200MHz clock input from MMCM
    .clk_in               (clk_out_200Mhz),           // input
    // 125 MHz clock from MMCM
    .gtx_clk_bufg_out     (),                         // output

    .phy_resetn           (phy_resetn_2),             // output


    // RGMII Interface
    .rgmii_txd            (rgmii_txd_2),              // output  [3:0]
    .rgmii_tx_ctl         (rgmii_tx_ctl_2),           // output
    .rgmii_txc            (rgmii_txc_2),              // output
    .rgmii_rxd            (rgmii_rxd_2),              // input   [3:0]
    .rgmii_rx_ctl         (rgmii_rx_ctl_2),           // input
    .rgmii_rxc            (rgmii_rxc_2),              // input


    // MDIO Interface
    .mdio                 (mdio_2),                   // inout
    .mdc                  (mdc_2),                    // output


    // Serialised statistics vectors
    .tx_statistics_s      (),                         // output
    .rx_statistics_s      (),                         // output

    // Serialised Pause interface controls
    .pause_req_s          (),                         // input

    // Main example design controls
    .mac_speed            (mac_speed_2_reg),          // input   [1:0]
    .update_speed         (update_speed_2),           // input
    .enable_address_swap  (enable_address_swap_2),    // input
    .enable_phy_loopback  (enable_phy_loopback_2),    // input
    .serial_response      (),                         // output
    .gen_tx_data          (gen_tx_data_2),            // input
    .chk_tx_data          (chk_tx_data_2),            // input
    .reset_error          (reset_error_2),            // input
    .frame_error          (led[4]),                   // output
    .frame_errorn         (),                         // output
    .activity_flash       (led[5]),                   // output
    .activity_flashn      (),                         // output

    .inband_link_status   (phy_link_status_2),        // output
    .inband_clock_speed   (phy_clock_speed_2),        // output  [1:0]
    .inband_duplex_status (phy_duplex_status_2),      // output
    .numOfPacketsSent     (numOfPacketsSent_2),       // output
    .numOfFramesReceived  (numOfFramesReceived_2),    // output
    .resetPacketCount     (resetPacketCount_2),       // input
    .loopbackEn           (loopbackEn_2),             // input
    .injectError          (injectError_2),            // input
    .loadAddresses        (loadAddresses_2),          // input
    .sourceAddress        (MACSourceAddress_2),       // input  [47:0]
    .destinationAddress   (MACDestinationAddress_2)   // input  [47:0]
);  
endmodule

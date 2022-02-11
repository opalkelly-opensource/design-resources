############################################################################
# XEM8320 - Xilinx constraints file
#
# Pin mappings for the XEM8320.  Use this as a template and comment out 
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
#
# Copyright (c) 2004-2021 Opal Kelly Incorporated
############################################################################

set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS True [current_design]

############################################################################
## FrontPanel Host Interface
############################################################################
set_property PACKAGE_PIN U20 [get_ports {okHU[0]}]
set_property PACKAGE_PIN U26 [get_ports {okHU[1]}]
set_property PACKAGE_PIN T22 [get_ports {okHU[2]}]
set_property SLEW FAST [get_ports {okHU[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okHU[*]}]

set_property PACKAGE_PIN V23 [get_ports {okUH[0]}]
set_property PACKAGE_PIN T23 [get_ports {okUH[1]}]
set_property PACKAGE_PIN U22 [get_ports {okUH[2]}]
set_property PACKAGE_PIN U25 [get_ports {okUH[3]}]
set_property PACKAGE_PIN U21 [get_ports {okUH[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUH[*]}]

set_property PACKAGE_PIN P26 [get_ports {okUHU[0]}]
set_property PACKAGE_PIN P25 [get_ports {okUHU[1]}]
set_property PACKAGE_PIN R26 [get_ports {okUHU[2]}]
set_property PACKAGE_PIN R25 [get_ports {okUHU[3]}]
set_property PACKAGE_PIN R23 [get_ports {okUHU[4]}]
set_property PACKAGE_PIN R22 [get_ports {okUHU[5]}]
set_property PACKAGE_PIN P21 [get_ports {okUHU[6]}]
set_property PACKAGE_PIN P20 [get_ports {okUHU[7]}]
set_property PACKAGE_PIN R21 [get_ports {okUHU[8]}]
set_property PACKAGE_PIN R20 [get_ports {okUHU[9]}]
set_property PACKAGE_PIN P23 [get_ports {okUHU[10]}]
set_property PACKAGE_PIN N23 [get_ports {okUHU[11]}]
set_property PACKAGE_PIN T25 [get_ports {okUHU[12]}]
set_property PACKAGE_PIN N24 [get_ports {okUHU[13]}]
set_property PACKAGE_PIN N22 [get_ports {okUHU[14]}]
set_property PACKAGE_PIN V26 [get_ports {okUHU[15]}]
set_property PACKAGE_PIN N19 [get_ports {okUHU[16]}]
set_property PACKAGE_PIN V21 [get_ports {okUHU[17]}]
set_property PACKAGE_PIN N21 [get_ports {okUHU[18]}]
set_property PACKAGE_PIN W20 [get_ports {okUHU[19]}]
set_property PACKAGE_PIN W26 [get_ports {okUHU[20]}]
set_property PACKAGE_PIN W19 [get_ports {okUHU[21]}]
set_property PACKAGE_PIN Y25 [get_ports {okUHU[22]}]
set_property PACKAGE_PIN Y26 [get_ports {okUHU[23]}]
set_property PACKAGE_PIN Y22 [get_ports {okUHU[24]}]
set_property PACKAGE_PIN V22 [get_ports {okUHU[25]}]
set_property PACKAGE_PIN W21 [get_ports {okUHU[26]}]
set_property PACKAGE_PIN AA23 [get_ports {okUHU[27]}]
set_property PACKAGE_PIN Y23 [get_ports {okUHU[28]}]
set_property PACKAGE_PIN AA24 [get_ports {okUHU[29]}]
set_property PACKAGE_PIN W25 [get_ports {okUHU[30]}]
set_property PACKAGE_PIN AA25 [get_ports {okUHU[31]}]
set_property SLEW FAST [get_ports {okUHU[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[*]}]


set_property PACKAGE_PIN T19 [get_ports {okAA}]
set_property IOSTANDARD LVCMOS18 [get_ports {okAA}]


create_clock -name okUH0 -period 9.920 [get_ports {okUH[0]}]

set_input_delay -add_delay -max -clock [get_clocks {okUH0}]  8.000 [get_ports {okUH[*]}]
set_input_delay -add_delay -min -clock [get_clocks {okUH0}] 9.920 [get_ports {okUH[*]}]
#set_multicycle_path -setup -from [get_ports {okUH[*]}] 2

set_input_delay -add_delay -max -clock [get_clocks {okUH0}]  7.000 [get_ports {okUHU[*]}]
set_input_delay -add_delay -min -clock [get_clocks {okUH0}]  2.000 [get_ports {okUHU[*]}]
#set_multicycle_path -setup -from [get_ports {okUHU[*]}] 2

set_output_delay -add_delay -max -clock [get_clocks {okUH0}]  2.000 [get_ports {okHU[*]}]
set_output_delay -add_delay -min -clock [get_clocks {okUH0}]  -0.500 [get_ports {okHU[*]}]

set_output_delay -add_delay -max -clock [get_clocks {okUH0}]  2.000 [get_ports {okUHU[*]}]
set_output_delay -add_delay -min -clock [get_clocks {okUH0}]  -0.500 [get_ports {okUHU[*]}]

create_clock -name fabric_100Mhz_p -period 10.000 [get_ports fabric_100Mhz_p]
set_input_jitter fabric_100Mhz_p 0.050

# 100 MHz input clock
set_property PACKAGE_PIN T24 [get_ports {fabric_100Mhz_p}]
set_property IOSTANDARD LVDS [get_ports {fabric_100Mhz_p}]

set_property PACKAGE_PIN U24 [get_ports {fabric_100Mhz_n}]
set_property IOSTANDARD LVDS [get_ports {fabric_100Mhz_n}]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk_out_IBUFDS_BUFG]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk_out_200Mhz]

############################################################################
## SYZYGY PORTA - SZG-ENET1G Peripheral
############################################################################
#### RGMII TX pins
# PORTA-34 (C2P_CLKp)
set_property PACKAGE_PIN H26 [get_ports rgmii_txc_1]
# PORTA-7 (S2_D0N)
set_property PACKAGE_PIN K18 [get_ports rgmii_tx_ctl_1]
# PORTA-10 (S5_D3P)
set_property PACKAGE_PIN L24 [get_ports rgmii_txd_1[0]]
# PORTA-12 (S7_D3N)
set_property PACKAGE_PIN L25 [get_ports rgmii_txd_1[1]]
# PORTA-14 (S9_D5P)
set_property PACKAGE_PIN K25 [get_ports rgmii_txd_1[2]]
# PORTA-16 (S11_D5N)
set_property PACKAGE_PIN K26 [get_ports rgmii_txd_1[3]]

#### RGMII RX pins
# PORTA-33 (P2C_CLKp)
set_property PACKAGE_PIN J23 [get_ports rgmii_rxc_1]
# PORTA-5 (S0_D0P)
set_property PACKAGE_PIN L18 [get_ports rgmii_rx_ctl_1]
# PORTA-15 (S10_D4N)
set_property PACKAGE_PIN J20 [get_ports rgmii_rxd_1[0]]
# PORTA-13 (S8_D4P)
set_property PACKAGE_PIN J19 [get_ports rgmii_rxd_1[1]]
# PORTA-11 (S6_D2N)
set_property PACKAGE_PIN M21 [get_ports rgmii_rxd_1[2]]
# PORTA-9 (S4_D2P)
set_property PACKAGE_PIN M20 [get_ports rgmii_rxd_1[3]]

#### Managment
# PORTA-20 (S15_D7N)
set_property PACKAGE_PIN K23 [get_ports mdio_1]
# PORTA-18 (S13_D7P)
set_property PACKAGE_PIN K22 [get_ports mdc_1]

#### MAC Address EEPROM
# PORTA-17 (S12_D6P)
set_property PACKAGE_PIN L22 [get_ports {sclk_portA}]
# PORTA-19 (S14_D6N)
set_property PACKAGE_PIN L23 [get_ports {sdata_portA}]

#### Reset
# PORTA-6 (S1_D1P)
set_property PACKAGE_PIN M25 [get_ports phy_resetn_1]


set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_txc_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_tx_ctl_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_txd_1[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_rxc_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_rx_ctl_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_rxd_1[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mdio_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {mdc_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {sclk_portA}]
set_property IOSTANDARD LVCMOS18 [get_ports {sdata_portA}]
set_property IOSTANDARD LVCMOS18 [get_ports {phy_resetn_1}]

# Xilinx's Tri-Mode Ethernet MAC example design uses the built-in self-calibrating 
# (BISC) controller in the I/O primitives so that extra interconnect logic is not 
# required to calibrate and maintain the clock to data adjustment. The following 
# constraint mutes the DRC PDRC-203 warning that BITSLICE_0 (sclk_portA) will not 
# be available during calibration and will only be available after BITSLICE_CONTROL.DLY_RDY 
# asserts. This stated issue did not raise any problems during testing as the state machine 
# to extract the MAC address from EEPROM seems to happen late enough in time.
set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports sclk_portA]

############################################################################
## SYZYGY PORTC - SZG-ENET1G Peripheral
############################################################################
#### RGMII TX pins
# PORTC-34 (C2P_CLKp)
set_property PACKAGE_PIN C17 [get_ports rgmii_txc_2]
# PORTC-7 (S2_D0N)
set_property PACKAGE_PIN E20 [get_ports rgmii_tx_ctl_2]
# PORTC-10 (S5_D3P)
set_property PACKAGE_PIN H17 [get_ports rgmii_txd_2[0]]
# PORTC-12 (S7_D3N)
set_property PACKAGE_PIN G17 [get_ports rgmii_txd_2[1]]
# PORTC-14 (S9_D5P)
set_property PACKAGE_PIN A17 [get_ports rgmii_txd_2[2]]
# PORTC-16 (S11_D5N)
set_property PACKAGE_PIN A18 [get_ports rgmii_txd_2[3]]

#### RGMII RX pins
# PORTC-33 (P2C_CLKp)
set_property PACKAGE_PIN E18 [get_ports rgmii_rxc_2]
# PORTC-5 (S0_D0P)
set_property PACKAGE_PIN F20 [get_ports rgmii_rx_ctl_2]
# PORTC-15 (S10_D4N)
set_property PACKAGE_PIN F19 [get_ports rgmii_rxd_2[0]]
# PORTC-13 (S8_D4P)
set_property PACKAGE_PIN F18 [get_ports rgmii_rxd_2[1]]
# PORTC-11 (S6_D2N)
set_property PACKAGE_PIN H19 [get_ports rgmii_rxd_2[2]]
# PORTC-9 (S4_D2P)
set_property PACKAGE_PIN H18 [get_ports rgmii_rxd_2[3]]

#### Managment
# PORTC-20 (S15_D7N)
set_property PACKAGE_PIN A15 [get_ports mdio_2]
# PORTC-18 (S13_D7P)
set_property PACKAGE_PIN B15 [get_ports mdc_2]

#### MAC Address EEPROM
# PORTC-17 (S12_D6P)
set_property PACKAGE_PIN E16 [get_ports {sclk_portC}]
# PORTC-19 (S14_D6N)
set_property PACKAGE_PIN E17 [get_ports {sdata_portC}]

#### Reset
# PORTC-6 (S1_D1P)
set_property PACKAGE_PIN C18 [get_ports phy_resetn_2]


set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_txc_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_tx_ctl_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_txd_2[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_rxc_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_rx_ctl_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_rxd_2[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mdio_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {mdc_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {sclk_portC}]
set_property IOSTANDARD LVCMOS18 [get_ports {sdata_portC}]
set_property IOSTANDARD LVCMOS18 [get_ports {phy_resetn_2}]

############################################################
# Input Delay Constraints
############################################################
# We have configured the PHY to add an internal delay of 2 ns onto the RX path. Ideally this would place the
# clock edge in the center of the 4 ns data valid window.
# DP83867 RGMII Timing Specifications:
# -Variation in nominal internal delay: .2 ns
# -I/O buffer skew: .35 ns
# We give a margin of .45 ns for PCB skew. Although this was not calculated, this is a very generious margin.
# This totals +- 1 ns skew.
# We shrink our 4 ns data valid windown down to 2 ns as a result of these calculations. 
set_input_delay -clock [get_clocks {rgmii_rxc_1}] -max -1 [get_ports {rgmii_rxd_1[*] rgmii_rx_ctl_1}]
set_input_delay -clock [get_clocks {rgmii_rxc_2}] -min 1 [get_ports {rgmii_rxd_1[*] rgmii_rx_ctl_1}]
set_input_delay -clock [get_clocks {rgmii_rxc_1}] -max -1 [get_ports {rgmii_rxd_2[*] rgmii_rx_ctl_2}]
set_input_delay -clock [get_clocks {rgmii_rxc_2}] -min 1 [get_ports {rgmii_rxd_2[*] rgmii_rx_ctl_2}]


set_input_delay -clock [get_clocks {rgmii_rxc_1}] -clock_fall -max -1 -add_delay [get_ports {rgmii_rxd_1[*] rgmii_rx_ctl_1}]
set_input_delay -clock [get_clocks {rgmii_rxc_1}] -clock_fall -min 1 -add_delay [get_ports {rgmii_rxd_1[*] rgmii_rx_ctl_1}]
set_input_delay -clock [get_clocks {rgmii_rxc_2}] -clock_fall -max -1 -add_delay [get_ports {rgmii_rxd_2[*] rgmii_rx_ctl_2}]
set_input_delay -clock [get_clocks {rgmii_rxc_2}] -clock_fall -min 1 -add_delay [get_ports {rgmii_rxd_2[*] rgmii_rx_ctl_2}]


############################################################
# Clock asynchronous groups
############################################################
# mmcm0_clk0 is equal to the okClk. Notify the timing tool that this clock is asynchronous to various clocks in the design.
set_clock_groups -asynchronous -group [get_clocks {mmcm0_clk0}] -group [get_clocks {clkout0}]
set_clock_groups -asynchronous -group [get_clocks {mmcm0_clk0}] -group [get_clocks {clkout0_1}]
set_clock_groups -asynchronous -group [get_clocks {mmcm0_clk0}] -group [get_clocks {clkout1}]
set_clock_groups -asynchronous -group [get_clocks {mmcm0_clk0}] -group [get_clocks {clkout1_1}]

set_clock_groups -asynchronous -group [get_clocks {mmcm0_clk0}] -group [get_clocks {rgmii_rxc_1}]
set_clock_groups -asynchronous -group [get_clocks {mmcm0_clk0}] -group [get_clocks {rgmii_rxc_2}]

# LEDS #####################################################################
set_property PACKAGE_PIN M24 [get_ports {led[0]}]
set_property PACKAGE_PIN F22 [get_ports {led[1]}]
set_property PACKAGE_PIN G22 [get_ports {led[2]}]
set_property PACKAGE_PIN G19 [get_ports {led[3]}]
set_property PACKAGE_PIN E22 [get_ports {led[4]}]
set_property PACKAGE_PIN B16 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[*]}]

# Set cells IO delay groups in the two different MAC example design instatiations. They will be assigned to the same group by default.
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_idelayctrl_common_i]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_rx_ctl]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_clk]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_clk_casc]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_ctl]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/rxdata_bus[0].delay_rgmii_rxd]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/rxdata_bus[1].delay_rgmii_rxd]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/rxdata_bus[2].delay_rgmii_rxd]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/rxdata_bus[3].delay_rgmii_rxd]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/txdata_out_bus[0].delay_rgmii_txd]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/txdata_out_bus[1].delay_rgmii_txd]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/txdata_out_bus[2].delay_rgmii_txd]
set_property IODELAY_GROUP mac_1 [get_cells EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/txdata_out_bus[3].delay_rgmii_txd]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_idelayctrl_common_i]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_rx_ctl]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_clk]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_clk_casc]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_ctl]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/rxdata_bus[0].delay_rgmii_rxd]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/rxdata_bus[1].delay_rgmii_rxd]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/rxdata_bus[2].delay_rgmii_rxd]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/rxdata_bus[3].delay_rgmii_rxd]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/txdata_out_bus[0].delay_rgmii_txd]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/txdata_out_bus[1].delay_rgmii_txd]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/txdata_out_bus[2].delay_rgmii_txd]
set_property IODELAY_GROUP mac_2 [get_cells EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/inst/tri_mode_ethernet_mac_i/rgmii_interface/txdata_out_bus[3].delay_rgmii_txd]



###################################################################
###################################################################
# Modified Xilinx Tri-Mode Ethernet MAC example design constraints.
# are located below this header.
###################################################################
###################################################################


############################################################
# Get auto-generated clock names                           #
############################################################
set axi_clk_name_1 [get_clocks -of [get_pins EthernetMac_1_example_design_i/example_clocks/clock_generator/mmcm_adv_inst/CLKOUT1]]
set axi_clk_name_2 [get_clocks -of [get_pins EthernetMac_2_example_design_i/example_clocks/clock_generator/mmcm_adv_inst/CLKOUT1]]


############################################################
# Output Delay constraints
############################################################
set_output_delay -clock $axi_clk_name_1 1 [get_ports mdc_1]
set_output_delay -clock $axi_clk_name_2 1 [get_ports mdc_2]

# no timing associated with output
set_false_path -from [get_cells -hier -filter {name =~ EthernetMac_1_example_design_i/*phy_resetn_int_reg}] -to [get_ports phy_resetn_1]
set_false_path -from [get_cells -hier -filter {name =~ EthernetMac_1_example_design_i/*phy_resetn_int_reg}] -to [get_ports phy_resetn_2]

############################################################
# Example design Clock Crossing Constraints                          #
############################################################
set_false_path -from [get_cells -hier -filter {name =~ EthernetMac_1_example_design_i/*phy_resetn_int_reg}] -to [get_cells -hier -filter {name =~ EthernetMac_1_example_design_i/*axi_lite_reset_gen/reset_sync*}]
set_false_path -from [get_cells -hier -filter {name =~ EthernetMac_2_example_design_i/*phy_resetn_int_reg}] -to [get_cells -hier -filter {name =~ EthernetMac_2_example_design_i/*axi_lite_reset_gen/reset_sync*}]


############################################################
# Ignore paths to resync flops
############################################################
set_false_path -to [get_pins -filter {REF_PIN_NAME =~ PRE} -of [get_cells -hier -regexp {.*\/reset_sync.*}]]
set_false_path -to [get_pins -filter {REF_PIN_NAME =~ D} -of [get_cells -regexp {.*\/.*_sync.*}]]

set_max_delay -from [get_cells EthernetMac_1_example_design_i/tx_stats_toggle_reg] -to [get_cells EthernetMac_1_example_design_i/tx_stats_sync/data_sync_reg0] 6 -datapath_only
set_max_delay -from [get_cells EthernetMac_2_example_design_i/tx_stats_toggle_reg] -to [get_cells EthernetMac_2_example_design_i/tx_stats_sync/data_sync_reg0] 6 -datapath_only
set_max_delay -from [get_cells EthernetMac_1_example_design_i/rx_stats_toggle_reg] -to [get_cells EthernetMac_1_example_design_i/rx_stats_sync/data_sync_reg0] 6 -datapath_only
set_max_delay -from [get_cells EthernetMac_2_example_design_i/rx_stats_toggle_reg] -to [get_cells EthernetMac_2_example_design_i/rx_stats_sync/data_sync_reg0] 6 -datapath_only



#
####
#######
##########
#############
#################
#FIFO BLOCK CONSTRAINTS

############################################################
# FIFO Clock Crossing Constraints                          #
############################################################

# control signal is synched separately so this is a false path
set_max_delay -from [get_cells -hier -filter {name =~ *rx_fifo_i/rd_addr_reg[*]}]                         -to [get_cells -hier -filter {name =~ *fifo*wr_rd_addr_reg[*]}] 3.2 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *rx_fifo_i/wr_store_frame_tog_reg}]                 -to [get_cells -hier -filter {name =~ *fifo_i/resync_wr_store_frame_tog/data_sync_reg0}] 3.2 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *rx_fifo_i/update_addr_tog_reg}]                    -to [get_cells -hier -filter {name =~ *rx_fifo_i/sync_rd_addr_tog/data_sync_reg0}] 3.2 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/rd_addr_txfer_reg[*]}]                   -to [get_cells -hier -filter {name =~ *fifo*wr_rd_addr_reg[*]}] 3.2 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/wr_frame_in_fifo_reg}]                   -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_wr_frame_in_fifo/data_sync_reg0}] 3.2 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/wr_frames_in_fifo_reg}]                  -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_wr_frames_in_fifo/data_sync_reg0}] 3.2 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/frame_in_fifo_valid_tog_reg}]            -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_fif_valid_tog/data_sync_reg0}] 3.2 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/rd_txfer_tog_reg}]                       -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_rd_txfer_tog/data_sync_reg0}] 3.2 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *tx_fifo_i/rd_tran_frame_tog_reg}]                  -to [get_cells -hier -filter {name =~ *tx_fifo_i/resync_rd_tran_frame_tog/data_sync_reg0}] 3.2 -datapath_only

set_power_opt -exclude_cells [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ *.bram.* }]


############################################################
# RGMII Delay Constraints                                  #
############################################################
# the following properties can be adjusted if required to adjust the 2ns skew on txc w.r.t txd
# DELAY_VALUE is the time represenatation of the desired delay in ps
#set_property DELAY_VALUE 1000 [get_cells {EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_clk}]
#set_property DELAY_VALUE 1000 [get_cells {EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_clk_casc}]
#set_property DELAY_VALUE 1000 [get_cells {EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_clk}]
#set_property DELAY_VALUE 1000 [get_cells {EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_clk_casc}]

# the following properties can be adjusted if requried to adjuct the IO timing
# the value shown is the default used by the IP
# increasing this value will improve the hold timing but will also add jitter.
#set_property DELAY_VALUE 500  [get_cells {EthernetMac_1_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_rx* trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/rxdata_bus[*].delay_rgmii_rx*}]
#set_property DELAY_VALUE 500  [get_cells {EthernetMac_2_example_design_i/trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_rx* trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/rxdata_bus[*].delay_rgmii_rx*}]

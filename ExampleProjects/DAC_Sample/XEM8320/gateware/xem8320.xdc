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

############################################################################
## System Clock
############################################################################
#set_property PACKAGE_PIN T24 [get_ports {sys_clkp}]
#set_property IOSTANDARD LVDS [get_ports {sys_clkp}]

#set_property PACKAGE_PIN U24 [get_ports {sys_clkn}]
#set_property IOSTANDARD LVDS [get_ports {sys_clkn}]

#create_clock -name sys_clk -period 10 [get_ports sys_clkp]
#set_clock_groups -asynchronous -group [get_clocks {sys_clk}] -group [get_clocks {mmcm0_clk0 okUH0}]

############################################################################
## SYZYGY Ports
############################################################################
## DAC ##
# PORTA-5 
set_property PACKAGE_PIN L18 [get_ports {dac_data[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[0]}]

# PORTA-6 
set_property PACKAGE_PIN M25 [get_ports {dac_data[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[1]}]

# PORTA-7 
set_property PACKAGE_PIN K18 [get_ports {dac_data[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[2]}]

# PORTA-8 
set_property PACKAGE_PIN M26 [get_ports {dac_data[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[3]}]

# PORTA-9 
set_property PACKAGE_PIN M20 [get_ports {dac_data[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[4]}]

# PORTA-10 
set_property PACKAGE_PIN L24 [get_ports {dac_data[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[5]}]

# PORTA-11 
set_property PACKAGE_PIN M21 [get_ports {dac_data[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[6]}]

# PORTA-12 
set_property PACKAGE_PIN L25 [get_ports {dac_data[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[7]}]

# PORTA-13 
set_property PACKAGE_PIN J19 [get_ports {dac_data[8]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[8]}]

# PORTA-14 
set_property PACKAGE_PIN K25 [get_ports {dac_data[9]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[9]}]

# PORTA-15 
set_property PACKAGE_PIN J20 [get_ports {dac_data[10]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[10]}]

# PORTA-16 
set_property PACKAGE_PIN K26 [get_ports {dac_data[11]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[11]}]

# PORTA-17 
set_property PACKAGE_PIN L22 [get_ports dac_cs_n]
set_property IOSTANDARD LVCMOS18 [get_ports dac_cs_n]

# PORTA-18 
set_property PACKAGE_PIN K22 [get_ports dac_sclk]
set_property IOSTANDARD LVCMOS18 [get_ports dac_sclk]

# PORTA-19 
set_property PACKAGE_PIN L23 [get_ports dac_sdio]
set_property IOSTANDARD LVCMOS18 [get_ports dac_sdio]

# PORTA-20 
set_property PACKAGE_PIN K23 [get_ports dac_opamp_en]
set_property IOSTANDARD LVCMOS18 [get_ports dac_opamp_en]

# PORTA-21 
set_property PACKAGE_PIN H24 [get_ports dac_reset_pinmd]
set_property IOSTANDARD LVCMOS18 [get_ports dac_reset_pinmd]

# PORTA-34 
set_property PACKAGE_PIN H26 [get_ports dac_clk]
set_property IOSTANDARD LVCMOS18 [get_ports dac_clk]

## I2S2 PMOD ##

# PORTD-13 
set_property PACKAGE_PIN J13 [get_ports i2s2_rx_sdin]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_rx_sdin]

# PORTD-14 
set_property PACKAGE_PIN AF14 [get_ports i2s2_tx_sdout]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_tx_sdout]

# PORTD-15 
set_property PACKAGE_PIN H13 [get_ports i2s2_rx_sclk]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_rx_sclk]

# PORTD-16 
set_property PACKAGE_PIN AF15 [get_ports i2s2_tx_sclk]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_tx_sclk]

# PORTD-17 
set_property PACKAGE_PIN AE13 [get_ports i2s2_rx_lrck]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_rx_lrck]

# PORTD-18 
set_property PACKAGE_PIN AC13 [get_ports i2s2_tx_lrck]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_tx_lrck]

# PORTD-19 
set_property PACKAGE_PIN AF13 [get_ports i2s2_rx_mclk]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_rx_mclk]

# PORTD-20 
set_property PACKAGE_PIN AC14 [get_ports i2s2_tx_mclk]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_tx_mclk]

# LEDS #####################################################################
set_property PACKAGE_PIN G19 [get_ports {led[0]}]
set_property PACKAGE_PIN B16 [get_ports {led[1]}]
set_property PACKAGE_PIN F22 [get_ports {led[2]}]
set_property PACKAGE_PIN E22 [get_ports {led[3]}]
set_property PACKAGE_PIN M24 [get_ports {led[4]}]
set_property PACKAGE_PIN G22 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[*]}]

############################################################################
## Timing
############################################################################
create_generated_clock -name dac_clk -source [get_pins szg_dac/dac_phy_impl/] -divide_by 1 [get_ports dac_clk]
set_output_delay -clock [get_clocks dac_clk] -clock_fall -min -add_delay -1.500 [get_ports {dac_data[*]}]
set_output_delay -clock [get_clocks dac_clk] -clock_fall -max -add_delay 0.250 [get_ports {dac_data[*]}]
set_output_delay -clock [get_clocks dac_clk] -min -add_delay -1.600 [get_ports {dac_data[*]}]
set_output_delay -clock [get_clocks dac_clk] -max -add_delay 0.130 [get_ports {dac_data[*]}]
